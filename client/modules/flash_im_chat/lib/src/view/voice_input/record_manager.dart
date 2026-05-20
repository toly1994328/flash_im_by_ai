import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as p;

/// 录音状态
enum RecordState { idle, recording, paused }

/// 录音管理器（单例）
///
/// 封装录音的开始、暂停、恢复、停止、取消操作。
class RecordManager {
  static final RecordManager _instance = RecordManager._internal();
  factory RecordManager() => _instance;
  RecordManager._internal();

  final AudioRecorder _recorder = AudioRecorder();
  RecordState _state = RecordState.idle;
  String? _currentPath;

  RecordState get state => _state;
  String? get currentPath => _currentPath;

  /// 开始录音
  Future<bool> startRecording({String? path}) async {
    if (_state != RecordState.idle) return false;
    try {
      if (await _recorder.hasPermission()) {
        _currentPath = path ?? await _getDefaultPath();
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: _currentPath!,
        );
        _state = RecordState.recording;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 暂停录音
  Future<void> pauseRecording() async {
    if (_state == RecordState.recording) {
      await _recorder.pause();
      _state = RecordState.paused;
    }
  }

  /// 恢复录音
  Future<void> resumeRecording() async {
    if (_state == RecordState.paused) {
      await _recorder.resume();
      _state = RecordState.recording;
    }
  }

  /// 停止录音并返回文件路径
  Future<String?> stopRecording() async {
    if (_state == RecordState.idle) return null;
    try {
      final path = await _recorder.stop();
      _state = RecordState.idle;
      _currentPath = null;
      return path;
    } catch (_) {
      _state = RecordState.idle;
      _currentPath = null;
      return null;
    }
  }

  /// 取消录音并删除文件
  Future<void> cancelRecording() async {
    if (_state != RecordState.idle) {
      await _recorder.cancel();
      if (_currentPath != null && File(_currentPath!).existsSync()) {
        File(_currentPath!).deleteSync();
      }
      _state = RecordState.idle;
      _currentPath = null;
    }
  }

  /// 检查麦克风权限
  Future<bool> hasPermission() => Permission.microphone.isGranted;

  /// 请求麦克风权限
  Future<bool> requestPermission() => _recorder.hasPermission();

  /// 获取默认录音文件路径
  Future<String> _getDefaultPath() async {
    final cache = await getApplicationCacheDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(cache.path, 'audio_$timestamp.wav');
  }

  void dispose() {
    _recorder.dispose();
  }
}
