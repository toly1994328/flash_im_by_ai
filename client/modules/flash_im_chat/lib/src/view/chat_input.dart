import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flash_shared/flash_shared.dart';
import 'mention_picker.dart';

class ChatInput extends StatefulWidget {
  final ValueChanged<String> onSend;
  final ValueChanged<String>? onSendImage;
  final ValueChanged<String>? onSendVideo;
  final ValueChanged<String>? onSendFile;
  final TextEditingController? controller;
  final bool isGroup;
  final String? groupAvatar;
  final List<MentionMember>? groupMembers;
  final Future<List<MentionMember>> Function()? membersFetcher;
  final bool isOwnerOrAdmin;
  final void Function(String content, List<Map<String, dynamic>> mentions)? onSendWithMentions;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onSendImage,
    this.onSendVideo,
    this.onSendFile,
    this.controller,
    this.isGroup = false,
    this.groupAvatar,
    this.groupMembers,
    this.membersFetcher,
    this.isOwnerOrAdmin = false,
    this.onSendWithMentions,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  late final TextEditingController _controller;
  bool _ownController = false;
  bool _hasText = false;
  bool _showMorePanel = false;
  bool _showMentionPicker = false;
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
    if (_ownController) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);

    // @检测：群聊中输入 @ 时弹出成员选择页面
    if (widget.isGroup) {
      final text = _controller.text;
      final offset = _controller.selection.baseOffset;
      if (offset > 0 && offset <= text.length && text[offset - 1] == '@') {
        _openMentionPicker();
      }
    }
  }

  void _onMentionSelected(String userId, String nickname) {
    final text = _controller.text;
    final offset = _controller.selection.baseOffset;
    // @ 字符已经在文本里了，在它后面插入 "昵称 "
    final insertText = '$nickname ';
    final newText = text.substring(0, offset) + insertText + text.substring(offset);
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: offset + insertText.length);

    // 记录 mention 信息（@ 的位置是 offset-1）
    _mentions.add(_MentionRecord(
      userId: userId,
      offset: offset - 1, // @ 字符的位置
      length: 1 + nickname.length, // @昵称（不含尾部空格）
    ));

    setState(() => _showMentionPicker = false);
  }

  Future<void> _openMentionPicker() async {
    // 获取成员列表
    List<MentionMember> members = widget.groupMembers ?? [];
    if (members.isEmpty && widget.membersFetcher != null) {
      members = await widget.membersFetcher!();
    }
    if (!mounted || members.isEmpty) return;

    // 转为 SelectableMember，复用 MemberPickerPage
    final selectableMembers = <SelectableMember>[
      // "所有人"选项（letter='!' 排最前，不显示分组标签，avatar=null 用品牌色默认图标）
      const SelectableMember(id: 'all', nickname: '所有人', avatar: null, letter: '!'),
      ...members.map((m) => SelectableMember(
        id: m.userId,
        nickname: m.nickname,
        avatar: m.avatar,
        letter: PinyinUtil.getFirstLetter(m.nickname),
      )),
    ];

    final result = await Navigator.of(context).push<MemberPickerResult>(
      MaterialPageRoute(
        builder: (_) => MemberPickerPage(
          members: selectableMembers,
          title: '选择提醒的人',
          confirmLabel: '确定',
          quickSelectIds: const {'all'},
          onConfirm: (r) {
            Navigator.of(context).pop(r);
          },
        ),
      ),
    );

    if (result != null && mounted) {
      // 逐个插入 @昵称
      for (final id in result.allIds) {
        if (id == 'all') {
          _onMentionSelected('all', '所有人');
        } else {
          final member = members.firstWhere((m) => m.userId == id, orElse: () => MentionMember(userId: id, nickname: '?'));
          _onMentionSelected(member.userId, member.nickname);
        }
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

  Future<void> _selectPhoto() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) widget.onSendImage?.call(image.path);
    setState(() => _showMorePanel = false);
  }

  Future<void> _takePhoto() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) widget.onSendImage?.call(image.path);
    setState(() => _showMorePanel = false);
  }

  Future<void> _selectVideo() async {
    final video = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (video != null) widget.onSendVideo?.call(video.path);
    setState(() => _showMorePanel = false);
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      widget.onSendFile?.call(result.files.single.path!);
    }
    setState(() => _showMorePanel = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
            ),
            child: Row(
              children: [
                // + 按钮
                GestureDetector(
                  onTap: () => setState(() => _showMorePanel = !_showMorePanel),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                // 输入框
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '输入消息...',
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    onTap: () {
                      if (_showMorePanel) setState(() => _showMorePanel = false);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                // 发送按钮
                IconButton(
                  onPressed: _hasText ? _send : null,
                  icon: Icon(Icons.send,
                    color: _hasText ? const Color(0xFF3B82F6) : Colors.grey),
                ),
              ],
            ),
          ),
          // 功能面板
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: _showMorePanel ? 200 : 0,
            child: _showMorePanel ? _buildMorePanel() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMorePanel() {
    return Container(
      color: const Color(0xFFF6F6F6),
      child: GridView.count(
        crossAxisCount: 4,
        padding: const EdgeInsets.all(20),
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          _buildMoreItem(Icons.photo_library, '照片', _selectPhoto),
          _buildMoreItem(Icons.camera_alt, '拍照', _takePhoto),
          _buildMoreItem(Icons.videocam, '视频', _selectVideo),
          _buildMoreItem(Icons.file_present_rounded, '文件', _selectFile),
        ],
      ),
    );
  }

  Widget _buildMoreItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 28, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

class _MentionRecord {
  final String userId;
  final int offset;
  final int length;
  const _MentionRecord({required this.userId, required this.offset, required this.length});
}

