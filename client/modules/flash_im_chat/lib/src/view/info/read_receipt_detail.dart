import 'package:flash_shared/flash_shared.dart';
import 'package:flutter/material.dart';

/// 已读成员信息
class _MemberInfo {
  final String userId;
  final String nickname;
  final String? avatar;

  const _MemberInfo({
    required this.userId,
    required this.nickname,
    this.avatar,
  });
}

/// 群聊已读详情弹窗
///
/// 显示"已读"和"未读"两个 Tab，每个 Tab 列出对应成员。
/// [fetcher] 由外部注入，返回 `{ "read_members": [...], "unread_members": [...] }`
class ReadReceiptDetailSheet extends StatefulWidget {
  final String messageId;
  final String conversationId;
  final String? baseUrl;
  final Future<Map<String, dynamic>> Function() fetcher;

  const ReadReceiptDetailSheet({
    super.key,
    required this.messageId,
    required this.conversationId,
    this.baseUrl,
    required this.fetcher,
  });

  @override
  State<ReadReceiptDetailSheet> createState() => _ReadReceiptDetailSheetState();
}

class _ReadReceiptDetailSheetState extends State<ReadReceiptDetailSheet> {
  List<_MemberInfo> _readMembers = [];
  List<_MemberInfo> _unreadMembers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await widget.fetcher();
      final readRaw = data['read_members'] as List<dynamic>? ?? [];
      final unreadRaw = data['unread_members'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _readMembers = readRaw.map((e) => _parseMember(e)).toList();
        _unreadMembers = unreadRaw.map((e) => _parseMember(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  _MemberInfo _parseMember(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return _MemberInfo(
        userId: (raw['user_id'] ?? raw['id'] ?? '').toString(),
        nickname: raw['nickname'] as String? ?? '',
        avatar: raw['avatar'] as String?,
      );
    }
    return _MemberInfo(userId: raw.toString(), nickname: raw.toString());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // 拖拽指示器
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // TabBar
            TabBar(
              labelColor: const Color(0xFF177EE6),
              unselectedLabelColor: const Color(0xFF999999),
              indicatorColor: const Color(0xFF177EE6),
              tabs: [
                Tab(text: '已读 ${_readMembers.length}'),
                Tab(text: '未读 ${_unreadMembers.length}'),
              ],
            ),
            // 内容
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: Colors.grey)))
                      : TabBarView(
                          children: [
                            _buildMemberList(_readMembers),
                            _buildMemberList(_unreadMembers),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberList(List<_MemberInfo> members) {
    if (members.isEmpty) {
      return const Center(
        child: Text('暂无', style: TextStyle(color: Color(0xFF999999))),
      );
    }
    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (_, index) {
        final member = members[index];
        return ListTile(
          leading: AvatarWidget(avatar: member.avatar, size: 36, borderRadius: 4),
          title: Text(
            member.nickname,
            style: const TextStyle(fontSize: 14),
          ),
        );
      },
    );
  }
}
