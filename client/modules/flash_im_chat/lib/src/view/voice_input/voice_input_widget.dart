import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fx_logger/fx_logger.dart';

import 'record_manager.dart';

/// 语音输入组件
///
/// 按住说话，松手发送，上滑取消。
class ImVoiceInput extends StatefulWidget {
  /// 录音完成回调：(文件路径, 时长毫秒)
  final void Function(String path, int durationMs) onSendAudio;

  const ImVoiceInput({super.key, required this.onSendAudio});

  @override
  State<ImVoiceInput> createState() => _ImVoiceInputState();
}

class _ImVoiceInputState extends State<ImVoiceInput> {
  static final _log = FxLog('Voice');

  final RecordManager _recordManager = RecordManager();
  bool _isRecording = false;
  bool _isCanceling = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  int _durationMs = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recordManager.hasPermission();
    if (!hasPermission) {
      // 没权限：请求权限后直接返回，不继续录音
      await _recordManager.requestPermission();
      return;
    }
    final started = await _recordManager.startRecording();
    if (!started) {
      _log.w('录音启动失败');
      return;
    }
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() => _durationMs = _stopwatch.elapsedMilliseconds);
    });
    setState(() {
      _isRecording = true;
      _isCanceling = false;
    });
  }

  Future<void> _stopAndSend() async {
    _stopwatch.stop();
    _timer?.cancel();
    final duration = _stopwatch.elapsedMilliseconds;

    if (duration < 1000) {
      await _recordManager.cancelRecording();
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('说话时间太短')),
        );
      }
      return;
    }

    final path = await _recordManager.stopRecording();
    setState(() => _isRecording = false);
    if (path != null) {
      _log.d('录音完成: ${duration}ms, path=$path');
      widget.onSendAudio(path, duration);
    }
  }

  Future<void> _cancel() async {
    _stopwatch.stop();
    _timer?.cancel();
    await _recordManager.cancelRecording();
    setState(() {
      _isRecording = false;
      _isCanceling = false;
    });
    _log.d('录音已取消');
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _startRecording();
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    // 上滑超过 50px 进入取消状态
    final canceling = details.offsetFromOrigin.dy < -50;
    if (canceling != _isCanceling) {
      setState(() => _isCanceling = canceling);
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_isRecording) return;
    if (_isCanceling) {
      _cancel();
    } else {
      _stopAndSend();
    }
  }

  String get _formattedDuration {
    final seconds = _durationMs ~/ 1000;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMoveUpdate,
      onLongPressEnd: _onLongPressEnd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4, right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isRecording
              ? (_isCanceling ? const Color(0xFFFFE0E0) : const Color(0xFFE0E0E0))
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          _isRecording
              ? (_isCanceling ? '松开 取消' : '松开 发送  $_formattedDuration')
              : '按住 说话',
          style: TextStyle(
            fontSize: 16,
            color: _isCanceling ? Colors.red : const Color(0xFF333333),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
