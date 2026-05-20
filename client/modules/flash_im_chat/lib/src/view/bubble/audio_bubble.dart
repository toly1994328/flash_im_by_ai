import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:fx_logger/fx_logger.dart';

import '../../data/message.dart';

/// 语音消息气泡
///
/// 显示时长 + 播放/暂停按钮，点击播放音频。
/// 气泡宽度按时长比例变化（最短 80，最长 200）。
class AudioBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final String? baseUrl;

  const AudioBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.baseUrl,
  });

  @override
  State<AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<AudioBubble> {
  static final _log = FxLog('Audio');

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  int get _durationMs => (widget.message.extra?['duration_ms'] as int?) ?? 0;

  String get _formattedDuration {
    final seconds = _durationMs ~/ 1000;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get _audioUrl {
    final content = widget.message.content;
    if (content.startsWith('http')) return content;
    if (widget.baseUrl != null) return '${widget.baseUrl}$content';
    return content;
  }

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final playing = state.playing;
      final completed = state.processingState == ProcessingState.completed;
      if (completed && _isPlaying) {
        setState(() => _isPlaying = false);
      } else if (playing != _isPlaying && !completed) {
        setState(() => _isPlaying = playing);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        final url = _audioUrl;
        if (_player.processingState == ProcessingState.completed ||
            _player.processingState == ProcessingState.idle) {
          await _player.setUrl(url);
        }
        await _player.play();
      }
    } catch (e) {
      _log.e('播放失败', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('语音播放失败')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isMe ? const Color(0xFFDBEAFE) : Colors.white;

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
