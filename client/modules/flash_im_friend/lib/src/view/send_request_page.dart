import 'package:flutter/material.dart';
import '../data/friend.dart';
import '../data/friend_repository.dart';

/// 申请添加朋友页（留言 + 发送）
class SendRequestPage extends StatefulWidget {
  final UserProfile profile;
  final FriendRepository repository;
  final VoidCallback? onSuccess;

  const SendRequestPage({
    super.key,
    required this.profile,
    required this.repository,
    this.onSuccess,
  });

  @override
  State<SendRequestPage> createState() => _SendRequestPageState();
}

class _SendRequestPageState extends State<SendRequestPage> {
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final message = _messageController.text.trim();
      await widget.repository.sendRequest(
        widget.profile.id,
        message: message.isEmpty ? null : message,
      );
      if (mounted) {
        widget.onSuccess?.call();
        // 返回到资料页之前（搜索页）
        Navigator.of(context).pop(); // 关闭申请页
        Navigator.of(context).pop(); // 关闭资料页
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('申请已发送'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        final msg = e.toString().contains('400') ? '已是好友' : '发送失败';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('申请添加朋友'),
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // 打招呼内容
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Text('打招呼内容', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _messageController,
              maxLength: 200,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '请输入验证信息',
                hintStyle: TextStyle(color: Color(0xFFCCCCCC)),
                border: InputBorder.none,
                counterText: '',
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const Spacer(),
          // 发送按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _sending
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('发送', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
