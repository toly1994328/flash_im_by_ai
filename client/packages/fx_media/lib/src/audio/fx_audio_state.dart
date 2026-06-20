/// 音频播放状态
enum FxAudioState { idle, loading, playing, paused, completed, error }

/// 音频播放信息快照
class FxAudioSnapshot {
  final FxAudioState state;
  final String? currentId;
  final Duration position;
  final Duration duration;

  const FxAudioSnapshot({
    this.state = FxAudioState.idle,
    this.currentId,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  FxAudioSnapshot copyWith({
    FxAudioState? state,
    String? currentId,
    Duration? position,
    Duration? duration,
  }) {
    return FxAudioSnapshot(
      state: state ?? this.state,
      currentId: currentId ?? this.currentId,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}
