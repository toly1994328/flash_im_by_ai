import 'package:flutter/material.dart';

/// 群成员信息（@选择用）
class MentionMember {
  final String userId;
  final String nickname;
  final String? avatar;

  const MentionMember({required this.userId, required this.nickname, this.avatar});
}

/// @成员选择浮层：输入框上方弹出，内部异步加载成员列表
class MentionPicker extends StatefulWidget {
  final List<MentionMember>? members; // 已有数据（可选）
  final Future<List<MentionMember>> Function()? fetcher; // 异步获取
  final bool showAll;
  final void Function(String userId, String nickname) onSelect;
  final VoidCallback onDismiss;

  const MentionPicker({
    super.key,
    this.members,
    this.fetcher,
    this.showAll = false,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  State<MentionPicker> createState() => _MentionPickerState();
}

class _MentionPickerState extends State<MentionPicker> {
  String _query = '';
  List<MentionMember> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.members != null && widget.members!.isNotEmpty) {
      _members = widget.members!;
      _loading = false;
    } else if (widget.fetcher != null) {
      _loadMembers();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadMembers() async {
    try {
      final result = await widget.fetcher!();
      if (mounted) setState(() { _members = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MentionMember> get _filtered {
    if (_query.isEmpty) return _members;
    return _members.where((m) =>
      m.nickname.toLowerCase().contains(_query.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 搜索框
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: '搜索成员',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFFBBBBBB)),
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                // 列表
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      if (widget.showAll && _query.isEmpty)
                        _buildItem('all', '所有人', isAll: true),
                      ..._filtered.map((m) => _buildItem(m.userId, m.nickname)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildItem(String userId, String nickname, {bool isAll = false}) {
    return InkWell(
      onTap: () => widget.onSelect(userId, isAll ? '所有人' : nickname),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isAll ? const Color(0xFF3B82F6) : const Color(0xFFE0E0E0),
              child: Icon(
                isAll ? Icons.groups : Icons.person,
                size: 14,
                color: isAll ? Colors.white : const Color(0xFF999999),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              nickname,
              style: TextStyle(
                fontSize: 14,
                color: isAll ? const Color(0xFF3B82F6) : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
