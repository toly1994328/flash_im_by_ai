import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/group_repository.dart';
import '../data/group_models.dart';
import '../logic/group_notification_cubit.dart';

/// 群通知页面（群主审批入群申请）
class GroupNotificationsPage extends StatefulWidget {
  final GroupRepository repository;
  final String? baseUrl;
  final GroupNotificationCubit? notificationCubit;

  const GroupNotificationsPage({
    super.key,
    required this.repository,
    this.baseUrl,
    this.notificationCubit,
  });

  @override
  State<GroupNotificationsPage> createState() => _GroupNotificationsPageState();
}

class _GroupNotificationsPageState extends State<GroupNotificationsPage> {
  List<JoinRequestItem> _requests = [];
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
      final requests = await widget.repository.getJoinRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests.where((r) => r.status == 0).toList();
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

  Future<void> _handle(JoinRequestItem request, bool approved) async {
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
      widget.notificationCubit?.decrementCount();
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败：$e')),
        );
      }
    }
  }

  String? _resolveUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http') || path.startsWith('identicon:')) return path;
    if (widget.baseUrl != null) return '${widget.baseUrl}$path';
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('群通知'),
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
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
            Text('加载失败', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
    }
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('暂无群通知', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text('当有人申请加入你的群聊时会显示在这里',
                style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(left: 68),
          child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF0F0F0)),
        ),
        itemBuilder: (context, index) => _buildItem(_requests[index]),
      ),
    );
  }

  Widget _buildItem(JoinRequestItem request) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AvatarWidget(avatar: _resolveUrl(request.avatar), size: 44, borderRadius: 6),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.nickname,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Text('申请加入 ', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                    Flexible(
                      child: Text(
                        request.groupName ?? '未命名群聊',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF333333), fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (request.message != null && request.message!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '留言：${request.message}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _handle(request, false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const Text('拒绝', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _handle(request, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('同意', style: TextStyle(fontSize: 13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
