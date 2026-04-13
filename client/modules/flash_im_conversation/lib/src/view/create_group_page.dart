import 'package:flash_shared/flash_shared.dart';
import 'package:flutter/material.dart';
import '../data/group_models.dart';

/// 创建群聊页面
///
/// 从好友列表中选择成员，输入群名称，创建群聊。
/// 参照参考项目 `screens/create_group_page.dart`。
class CreateGroupPage extends StatefulWidget {
  final List<SelectableMember> members;
  final Set<String> initialSelectedIds;

  const CreateGroupPage({
    super.key,
    required this.members,
    this.initialSelectedIds = const {},
  });

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nameController = TextEditingController();
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.initialSelectedIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _nameController.text.trim().isNotEmpty && _selectedIds.length >= 2;

  void _toggleMember(String id) {
    if (widget.initialSelectedIds.contains(id)) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _submit() {
    if (!_canCreate) return;
    Navigator.pop(
      context,
      CreateGroupResult(
        name: _nameController.text.trim(),
        memberIds: _selectedIds.map((id) => int.parse(id)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('创建群聊'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _canCreate ? _submit : null,
            child: Text(
              '创建(${_selectedIds.length})',
              style: TextStyle(
                color: _canCreate
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '群名称',
                hintText: '请输入群名称',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.group),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '已选择 ${_selectedIds.length} 人',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.members.isEmpty
                ? const Center(
                    child: Text('暂无好友', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: widget.members.length,
                    itemBuilder: (context, index) {
                      final member = widget.members[index];
                      final isSelected = _selectedIds.contains(member.id);
                      final isLocked = widget.initialSelectedIds.contains(member.id);
                      return ListTile(
                        leading: AvatarWidget(
                          avatar: member.avatar,
                          size: 40,
                          borderRadius: 4,
                        ),
                        title: Text(member.nickname),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: isLocked ? null : (_) => _toggleMember(member.id),
                          shape: const CircleBorder(),
                        ),
                        onTap: isLocked ? null : () => _toggleMember(member.id),
                        tileColor: isSelected
                            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
