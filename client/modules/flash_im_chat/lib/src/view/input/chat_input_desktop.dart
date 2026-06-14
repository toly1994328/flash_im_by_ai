import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flash_shared/flash_shared.dart';
import 'package:tolyui_feedback/tolyui_feedback.dart';

import 'emoji_panel.dart';
import 'mention_picker.dart';

/// 桌面端聊天输入框
///
/// 微信桌面端风格：工具栏在上，多行输入区在下，发送按钮右下角
class ChatInputDesktop extends StatefulWidget {
  final ValueChanged<String> onSend;
  final ValueChanged<String>? onSendImage;
  final ValueChanged<String>? onSendVideo;
  final ValueChanged<String>? onSendFile;
  final TextEditingController? controller;
  final bool isGroup;
  final List<MentionMember>? groupMembers;
  final Future<List<MentionMember>> Function()? membersFetcher;
  final void Function(String content, List<Map<String, dynamic>> mentions)? onSendWithMentions;

  const ChatInputDesktop({
    super.key,
    required this.onSend,
    this.onSendImage,
    this.onSendVideo,
    this.onSendFile,
    this.controller,
    this.isGroup = false,
    this.groupMembers,
    this.membersFetcher,
    this.onSendWithMentions,
  });

  @override
  State<ChatInputDesktop> createState() => _ChatInputDesktopState();
}

class _ChatInputDesktopState extends State<ChatInputDesktop> {
  late final TextEditingController _controller;
  bool _ownController = false;
  bool _hasText = false;
  final FocusNode _focusNode = FocusNode();
  final List<_MentionRecord> _mentions = [];

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownController = true;
    }
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (_ownController) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);

    if (widget.isGroup) {
      final text = _controller.text;
      final offset = _controller.selection.baseOffset;
      if (offset > 0 && offset <= text.length && text[offset - 1] == '@') {
        _openMentionPicker();
      }
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_mentions.isNotEmpty && widget.onSendWithMentions != null) {
      final mentionData = _mentions.map((m) => {
        'user_id': m.userId,
        'offset': m.offset,
        'length': m.length,
      }).toList();
      widget.onSendWithMentions!(text, mentionData);
    } else {
      widget.onSend(text);
    }
    _controller.clear();
    _mentions.clear();
  }

  void _onEmojiSelected(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;
    final offset = selection.baseOffset.clamp(0, text.length);
    final newText = text.substring(0, offset) + emoji + text.substring(offset);
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: offset + emoji.length);
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      widget.onSendFile?.call(result.files.single.path!);
    }
  }

  Future<void> _selectImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      widget.onSendImage?.call(result.files.single.path!);
    }
  }

  void _onMentionSelected(String userId, String nickname) {
    final text = _controller.text;
    final offset = _controller.selection.baseOffset;
    final insertText = '$nickname ';
    final newText = text.substring(0, offset) + insertText + text.substring(offset);
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: offset + insertText.length);
    _mentions.add(_MentionRecord(
      userId: userId,
      offset: offset - 1,
      length: 1 + nickname.length,
    ));
  }

  Future<void> _openMentionPicker() async {
    if (!widget.isGroup) return;
    List<MentionMember> members = widget.groupMembers ?? [];
    if (members.isEmpty && widget.membersFetcher != null) {
      members = await widget.membersFetcher!();
    }
    if (!mounted || members.isEmpty) return;

    final List<SelectableMember> selectableMembers = <SelectableMember>[
      const SelectableMember(id: 'all', nickname: '所有人', avatar: null, letter: '!'),
      ...members.map((MentionMember m) => SelectableMember(
        id: m.userId,
        nickname: m.nickname,
        avatar: m.avatar,
        letter: PinyinUtil.getFirstLetter(m.nickname),
      )),
    ];

    final MemberPickerResult? result = await adaptivePush<MemberPickerResult>(
      context,
      builder: (_) => MemberPickerPage(
        members: selectableMembers,
        title: '选择提醒的人',
        confirmLabel: '确定',
        quickSelectIds: const {'all'},
        onConfirm: (MemberPickerResult r) => Navigator.of(context).pop(r),
      ),
    );

    if (result != null && mounted) {
      for (final String id in result.allIds) {
        if (id == 'all') {
          _onMentionSelected('all', '所有人');
        } else {
          final MentionMember member = members.firstWhere(
            (MentionMember m) => m.userId == id,
            orElse: () => MentionMember(userId: id, nickname: '?'),
          );
          _onMentionSelected(member.userId, member.nickname);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 输入区域
          Container(
            constraints: const BoxConstraints(minHeight: 100, maxHeight: 160),
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed) {
                  _send();
                }
              },
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  isDense: true,
                ),
                minLines: 3,
                maxLines: 6,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ),
          // 工具栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                TolyPopover(
                  placement: Placement.topStart,
                  maxWidth: 400,
                  maxHeight: 520,
                  decorationConfig: DecorationConfig(
                    backgroundColor: Colors.white,
                    radius: const Radius.circular(12),
                  ),
                  overlay: EmojiPanel(onEmojiSelected: _onEmojiSelected, height: 360),
                  builder: (context, ctrl, child) => GestureDetector(
                    onTap: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
                    child: child,
                  ),
                  child: const Icon(Icons.emoji_emotions_outlined, size: 22, color: Color(0xFF666666)),
                ),
                const SizedBox(width: 20),
                _buildToolIcon(Icons.image_outlined, _selectImage),
                const SizedBox(width: 20),
                _buildToolIcon(Icons.folder_outlined, _selectFile),
                if (widget.isGroup) ...[
                  const SizedBox(width: 20),
                  _buildToolIcon(Icons.alternate_email, () {
                    final String text = _controller.text;
                    final int offset = _controller.selection.baseOffset.clamp(0, text.length);
                    final String newText = '${text.substring(0, offset)}@${text.substring(offset)}';
                    _controller.text = newText;
                    _controller.selection = TextSelection.collapsed(offset: offset + 1);
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 22, color: const Color(0xFF666666)),
    );
  }
}

class _MentionRecord {
  final String userId;
  final int offset;
  final int length;
  const _MentionRecord({required this.userId, required this.offset, required this.length});
}
