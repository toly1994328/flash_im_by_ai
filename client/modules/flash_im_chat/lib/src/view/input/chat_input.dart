import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flash_shared/flash_shared.dart';

import 'emoji_panel.dart';
import 'mention_picker.dart';
import '../voice_input/voice_input_widget.dart';

/// 输入栏底部面板模式
enum _PanelMode { none, emoji, more }

class ChatInput extends StatefulWidget {
  final ValueChanged<String> onSend;
  final ValueChanged<String>? onSendImage;
  final ValueChanged<String>? onSendVideo;
  final ValueChanged<String>? onSendFile;
  final void Function(String path, int durationMs)? onSendAudio;
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
    this.onSendAudio,
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
  bool _isVoiceMode = false;
  _PanelMode _panelMode = _PanelMode.none;
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

    // @检测：群聊中输入 @ 时弹出成员选择页面
    if (widget.isGroup) {
      final text = _controller.text;
      final offset = _controller.selection.baseOffset;
      if (offset > 0 && offset <= text.length && text[offset - 1] == '@') {
        _openMentionPicker();
      }
    }
  }

  // ─── 面板切换 ───

  void _onTapEmoji() {
    if (_panelMode == _PanelMode.emoji) {
      // 再次点击表情图标 → 收起面板，弹起键盘
      setState(() => _panelMode = _PanelMode.none);
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() {
        _panelMode = _PanelMode.emoji;
        _isVoiceMode = false;
      });
    }
  }

  void _onTapMore() {
    if (_panelMode == _PanelMode.more) {
      setState(() => _panelMode = _PanelMode.none);
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() {
        _panelMode = _PanelMode.more;
        _isVoiceMode = false;
      });
    }
  }

  void _onTapMic() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
      _panelMode = _PanelMode.none;
    });
    if (_isVoiceMode) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  void _onTapTextField() {
    if (_panelMode != _PanelMode.none) {
      setState(() => _panelMode = _PanelMode.none);
    }
    if (_isVoiceMode) {
      setState(() => _isVoiceMode = false);
    }
  }

  void _onEmojiSelected(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;
    final offset = selection.baseOffset.clamp(0, text.length);
    final newText = text.substring(0, offset) + emoji + text.substring(offset);
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: offset + emoji.length);
  }

  // ─── 发送 ───

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

  void _onSendAudio(String path, int durationMs) {
    widget.onSendAudio?.call(path, durationMs);
  }

  // ─── 更多面板操作 ───

  Future<void> _selectPhoto() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) widget.onSendImage?.call(image.path);
    setState(() => _panelMode = _PanelMode.none);
  }

  Future<void> _takePhoto() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) widget.onSendImage?.call(image.path);
    setState(() => _panelMode = _PanelMode.none);
  }

  Future<void> _selectVideo() async {
    final video = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (video != null) widget.onSendVideo?.call(video.path);
    setState(() => _panelMode = _PanelMode.none);
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      widget.onSendFile?.call(result.files.single.path!);
    }
    setState(() => _panelMode = _PanelMode.none);
  }

  // ─── @提及 ───

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
    setState(() {});
  }

  Future<void> _openMentionPicker() async {
    List<MentionMember> members = widget.groupMembers ?? [];
    if (members.isEmpty && widget.membersFetcher != null) {
      members = await widget.membersFetcher!();
    }
    if (!mounted || members.isEmpty) return;

    final selectableMembers = <SelectableMember>[
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
          onConfirm: (r) => Navigator.of(context).pop(r),
        ),
      ),
    );

    if (result != null && mounted) {
      for (final id in result.allIds) {
        if (id == 'all') {
          _onMentionSelected('all', '所有人');
        } else {
          final member = members.firstWhere(
            (m) => m.userId == id,
            orElse: () => MentionMember(userId: id, nickname: '?'),
          );
          _onMentionSelected(member.userId, member.nickname);
        }
      }
    }
  }

  // ─── 构建 ───

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: 'chat-input',
      onTapOutside: (_) {
        if (_panelMode != _PanelMode.none) {
          setState(() => _panelMode = _PanelMode.none);
        }
        _focusNode.unfocus();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInputBar(),
          _buildPanel(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF6F6F6),
        border: Border(top: BorderSide(color: Color(0xFFDDDDDD), width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 麦克风 / 键盘切换
            GestureDetector(
              onTap: _onTapMic,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: SvgPicture.asset(
                  _isVoiceMode
                      ? 'assets/icons/ic_keyboard.svg'
                      : 'assets/icons/ic_voice.svg',
                  package: 'flash_im_chat',
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(Colors.grey[600]!, BlendMode.srcIn),
                ),
              ),
            ),
            // 输入框 / 语音按钮
            Expanded(child: _isVoiceMode ? _buildVoiceButton() : _buildTextField()),
            // 表情图标
            _buildIconButton(
              icon: _panelMode == _PanelMode.emoji
                  ? Icons.keyboard
                  : Icons.emoji_emotions_outlined,
              onTap: _onTapEmoji,
            ),
            // + 更多（有文字时隐藏）
            if (!_hasText || _isVoiceMode)
              _buildIconButton(
                icon: Icons.add_circle_outline_rounded,
                onTap: _onTapMore,
              ),
            // 发送按钮（有文字时显示）
            if (_hasText && !_isVoiceMode) _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Icon(icon, size: 28, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        minLines: 1,
        maxLines: 8,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _send(),
        onTap: _onTapTextField,
      ),
    );
  }

  Widget _buildVoiceButton() {
    return ImVoiceInput(onSendAudio: _onSendAudio);
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _send,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Container(
          height: 28,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            '发送',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: _panelMode != _PanelMode.none ? 200 : 0,
      child: _buildPanelContent(),
    );
  }

  Widget? _buildPanelContent() {
    return switch (_panelMode) {
      _PanelMode.emoji => EmojiPanel(onEmojiSelected: _onEmojiSelected),
      _PanelMode.more => _buildMorePanel(),
      _PanelMode.none => null,
    };
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
            child: Icon(icon, size: 28, color: const Color(0xFF555555)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
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
