import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';

/// 修改群聊名称页面
class EditGroupNamePage extends StatefulWidget {
  final String currentName;
  final String? avatar;

  const EditGroupNamePage({
    super.key,
    required this.currentName,
    this.avatar,
  });

  @override
  State<EditGroupNamePage> createState() => _EditGroupNamePageState();
}

class _EditGroupNamePageState extends State<EditGroupNamePage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canConfirm {
    final text = _controller.text.trim();
    return text.isNotEmpty && text != widget.currentName;
  }

  void _confirm() {
    if (!_canConfirm) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  Widget _buildAvatar(double size) {
    final avatar = widget.avatar;
    if (avatar != null && avatar.startsWith('grid:')) {
      final avatarList = avatar.substring(5).split(',');
      final members = <GroupAvatarMember>[];
      for (var i = 0; i < avatarList.length; i++) {
        final a = avatarList[i].trim();
        members.add(GroupAvatarMember(
          id: 'member_$i',
          avatarUrl: a.isNotEmpty ? a : null,
        ));
      }
      return GroupAvatarWidget(members: members, size: size, borderRadius: 6);
    }
    return AvatarWidget(avatar: avatar, size: size, borderRadius: 6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: true,
        title: const SizedBox.shrink(),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          // 标题
          const Text(
            '修改群聊名称',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 10),
          // 说明文字
          const Text(
            '修改群聊名称后，将在群内通知其他成员。',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 40),
          // 输入区域：头像 + 输入框 + 底部分割线
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E5E5)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      _buildAvatar(36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          maxLength: 30,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _confirm(),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E5E5)),
              ],
            ),
          ),
          const Spacer(),
          // 底部确定按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 56, 64),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: _canConfirm ? _confirm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    disabledBackgroundColor: const Color(0xFFEEEEEE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '确定',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _canConfirm ? Colors.white : const Color(0xFFBBBBBB),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
