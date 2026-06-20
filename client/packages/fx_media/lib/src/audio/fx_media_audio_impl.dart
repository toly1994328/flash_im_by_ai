import 'dart:async';

import 'package:fx_logger/fx_logger.dart';
import 'package:just_audio/just_audio.dart';

import 'fx_audio_state.dart';
import 'fx_media_audio.dart';

/// FxMediaAudio 实现：单 AudioPlayer 实例，播新停旧
class FxMediaAudioImpl implements FxMediaAudio {
  static final FxLog _log = FxLog('FxAudio');

  final AudioPlayer _player = AudioPlayer();
  String? _currentId;
  String? _currentSource;
  FxAudioSnapshot _lastSnapshot = const FxAudioSnapshot();

  final StreamController<FxAudioSnapshot> _snapshotController =
      StreamController<FxAudioSnapshot>.broadcast();

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  FxMediaAudioImpl() {
    _stateSub = _player.playerStateStream.listen(_onPlayerState);
    _positionSub = _player.positionStream.listen(_onPosition);
    _durationSub = _player.durationStream.listen(_onDuration);
  }

  @override
  String? get currentId => _currentId;

  @override
  Stream<FxAudioSnapshot> get snapshotStream => _snapshotController.stream;

  @override
  Future<void> play(String url, {String? id}) async {
    final String effectiveId = id ?? url;
    try {
      if (_currentId == effectiveId && _currentSource == url) {
        // 同一资源：恢复播放
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
        return;
      }
      // 切换资源
      _currentId = effectiveId;
      _currentSource = url;
      _emitSnapshot(FxAudioState.loading);
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      _log.e('play failed', error: e);
      _emitSnapshot(FxAudioState.error);
    }
  }

  @override
  Future<void> playFile(String localPath, {String? id}) async {
    final String effectiveId = id ?? localPath;
    try {
      if (_currentId == effectiveId && _currentSource == localPath) {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
        return;
      }
      _currentId = effectiveId;
      _currentSource = localPath;
      _emitSnapshot(FxAudioState.loading);
      await _player.setFilePath(localPath);
      await _player.play();
    } catch (e) {
      _log.e('playFile failed', error: e);
      _emitSnapshot(FxAudioState.error);
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> resume() async {
    await _player.play();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentId = null;
    _currentSource = null;
    _emitSnapshot(FxAudioState.idle);
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    _snapshotController.close();
  }

  // ─── 内部方法 ───

  void _onPlayerState(PlayerState state) {
    final FxAudioState audioState = switch (state.processingState) {
      ProcessingState.idle => FxAudioState.idle,
      ProcessingState.loading => FxAudioState.loading,
      ProcessingState.buffering => FxAudioState.loading,
      ProcessingState.ready => state.playing ? FxAudioState.playing : FxAudioState.paused,
      ProcessingState.completed => FxAudioState.completed,
    };
    _emitSnapshot(audioState);
  }

  void _onPosition(Duration position) {
    _lastSnapshot = _lastSnapshot.copyWith(position: position);
    _emit(_lastSnapshot);
  }

  void _onDuration(Duration? duration) {
    if (duration != null) {
      _lastSnapshot = _lastSnapshot.copyWith(duration: duration);
      _emit(_lastSnapshot);
    }
  }

  void _emitSnapshot(FxAudioState state) {
    _lastSnapshot = _lastSnapshot.copyWith(state: state, currentId: _currentId);
    _emit(_lastSnapshot);
  }

  void _emit(FxAudioSnapshot snapshot) {
    if (!_snapshotController.isClosed) {
      _snapshotController.add(snapshot);
    }
  }
}
