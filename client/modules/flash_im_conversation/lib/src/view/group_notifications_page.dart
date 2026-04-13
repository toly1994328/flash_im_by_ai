import 'package:flash_shared/flash_shared.dart';
import 'package:flutter/material.dart';
import '../data/conversation_repository.dart';
import '../data/group_models.dart';

/// 群通知页面（群主查看/处理入群申请）
class GroupNotificationsPage extends StatefulWidget {
  final ConversationRepository repository;

  const GroupNotificationsPage({super.key, required this.repository});

  @override
  State<GroupNotificationsPage> createState() => _GroupNotificationsPageState();
}

class _GroupNotificationsPageState extends State<GroupNotificationsPage> {
  List<MyGroupNotification> _requests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final requests = await widget.repository.getMyJoinRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handle(MyGroupNotification request, bool approved) async {
    try {
      await widget.repository.handleJoinRequest(
        request.conversationId,
        request.id,
        approved: approved,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approved ? '已同意' : '已拒绝')),
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('群通知')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
    }
    if (_requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 48, color: Color(0xFFCCCCCC)),
            SizedBox(height: 12),
            Text('暂无群通知', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
            SizedBox(height: 4),
            Text('当有人申请加入你的群聊时会显示在这里',
              style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => _buildRequestItem(_requests[index]),
      ),
    );
  }

  Widget _buildRequestItem(MyGroupNotification request) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          AvatarWidget(avatar: request.avatar, size: 44, borderRadius: 4),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.nickname,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('申请加入 ${request.groupName ?? "未命名群聊"}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                if (request.message != null && request.message!.isNotEmpty)
                  Text('留言：${request.message}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _handle(request, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('拒绝'),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: () => _handle(request, true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('同意'),
          ),
        ],
      ),
    );
  }
}
