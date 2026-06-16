```dart
import 'package:flutter/material.dart';
import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';
import 'package:video_player/video_player.dart';

/// 实现 VideoPlayerHandle（包装 video_player）
class VPHandle implements VideoPlayerHandle {
  final VideoPlayerController _controller;

  VPHandle(this._controller);

  @override
  Widget get playerWidget => VideoPlayer(_controller);

  @override
  ValueNotifier<VideoPlaybackState> get state => _state;
  final ValueNotifier<VideoPlaybackState> _state =
      ValueNotifier<VideoPlaybackState>(const VideoPlaybackState());

  void _sync() {
    final VideoPlayerValue v = _controller.value;
    _state.value = VideoPlaybackState(
      position: v.position,
      duration: v.duration,
      isPlaying: v.isPlaying,
      isBuffering: v.isBuffering,
      isInitialized: v.isInitialized,
      aspectRatio: v.aspectRatio,
      isCompleted: v.position >= v.duration,
    );
  }

  @override
  Future<void> play() async {
    _controller.addListener(_sync);
    await _controller.play();
  }

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> seekTo(Duration position) => _controller.seekTo(position);

  @override
  Future<void> dispose() async {
    _controller.removeListener(_sync);
    await _controller.dispose();
  }
}

/// 实现 VideoPlayerResolver
class MyVideoPlayerResolver implements VideoPlayerResolver {
  const MyVideoPlayerResolver();

  @override
  Future<VideoPlayerHandle> create(VideoMeta meta) async {
    final Uri uri = switch (meta.source) {
      NetworkSource(:final uri) => uri,
      FileSource(:final path) => Uri.file(path),
      _ => throw UnimplementedError('不支持的视频源类型'),
    };

    final VideoPlayerController controller =
        VideoPlayerController.networkUrl(uri);
    await controller.initialize();
    return VPHandle(controller);
  }
}

/// 在 App 顶层注入
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return VideoPlayerProvider(
      resolver: const MyVideoPlayerResolver(),
      child: MediaSourceProvider(
        resolver: const CachedMediaSourceResolver(),
        child: MaterialApp(home: const HomePage()),
      ),
    );
  }
}
```
