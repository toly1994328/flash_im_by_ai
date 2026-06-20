import 'fx_audio_state.dart';

/// 全局音频播放器抽象接口
abstract class FxMediaAudio {
  /// 播放网络音频（自动停止当前正在播放的）
  Future<void> play(String url, {String? id});

  /// 播放本地文件
  Future<void> playFile(String localPath, {String? id});

  /// 暂停
  Future<void> pause();

  /// 恢复播放
  Future<void> resume();

  /// 停止
  Future<void> stop();

  /// 当前播放的资源 id
  String? get currentId;

  /// 状态快照流
  Stream<FxAudioSnapshot> get snapshotStream;

  /// 释放资源
  void dispose();
}
