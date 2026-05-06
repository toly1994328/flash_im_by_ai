import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ChatInput extends StatefulWidget {
  final ValueChanged<String> onSend;
  final ValueChanged<String>? onSendImage;
  final ValueChanged<String>? onSendVideo;
  final ValueChanged<String>? onSendFile;
  final TextEditingController? controller;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onSendImage,
    this.onSendVideo,
    this.onSendFile,
    this.controller,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  late final TextEditingController _controller;
  bool _ownController = false;
  bool _hasText = false;
  bool _showMorePanel = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownController = true;
    }
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    if (_ownController) _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
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
