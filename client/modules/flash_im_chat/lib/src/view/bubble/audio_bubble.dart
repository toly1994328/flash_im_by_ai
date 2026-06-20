import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fx_media/fx_media.dart';

import '../../data/message.dart';

/// 语音消息气泡
///
/// 显示时长 + 播放/暂停按钮，点击播放音频。
/// 气泡宽度按时长比例变化（最短 80，最长 200）。
class AudioBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final String? baseUrl;
  final String? localPath;

  const AudioBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.baseUrl,
    this.localPath,
  });

  @override
  State<AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<AudioBubble> {
  StreamSubscription<FxAudioSnapshot>? _sub;

  String get _audioId => widget.message.id;

  int get _durationMs => (widget.message.extra?['duration_ms'] as int?) ?? 0;

  String get _formattedDuration {
    final int seconds = _durationMs ~/ 1000;
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get _audioUrl {
    if (widget.localPath != null) return widget.localPath!;
    final String content = widget.message.content;
    if (content.startsWith('http')) return content;
    if (widget.baseUrl != null) return '${widget.baseUrl}$content';
    return content;
  }

  bool get _isLocalFile {
    if (widget.localPath != null) return true;
    final String content = widget.message.content;
    return !content.startsWith('http') && !content.startsWith('/uploads');
  }

  bool get _isPlaying {
    final String? current = FxMedia.audio.currentId;
    return current == _audioId;
  }

  @override
  void initState() {
    super.initState();
    _sub = FxMedia.audio.snapshotStream.listen((FxAudioSnapshot snapshot) {
      if (!mounted) return;
      // 只在和自己相关的状态变化时 rebuild
      if (snapshot.currentId == _audioId || FxMedia.audio.currentId == null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await FxMedia.audio.pause();
    } else {
      final String url = _audioUrl;
      if (_isLocalFile) {
        await FxMedia.audio.playFile(url, id: _audioId);
      } else {
        await FxMedia.audio.play(url, id: _audioId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isMe ? const Color(0xFFDBEAFE) : Colors.white;

    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 22,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(width: 6),
            Text(
              _formattedDuration,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.multitrack_audio,
              size: 16,
              color: Color(0xFF3B82F6),
            ),
          ],
        ),
      ),
    );
  }
}
