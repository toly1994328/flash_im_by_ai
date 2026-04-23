import 'package:flutter/material.dart';
import '../data/group_repository.dart';

/// 群公告页面
///
/// 查看模式：展示公告内容或空状态
/// 编辑模式（仅群主）：TextField 编辑 + 发布
class GroupAnnouncementPage extends StatefulWidget {
  final GroupRepository repository;
  final String conversationId;
  final String? currentAnnouncement;
  final bool isOwner;

  const GroupAnnouncementPage({
    super.key,
    required this.repository,
    required this.conversationId,
    this.currentAnnouncement,
    this.isOwner = false,
  });

  @override
  State<GroupAnnouncementPage> createState() => _GroupAnnouncementPageState();
}

class _GroupAnnouncementPageState extends State<GroupAnnouncementPage> {
  bool _isEditing = false;
  bool _isPublishing = false;
  late final TextEditingController _controller;
  late String? _announcement;

  @override
  void initState() {
    super.initState();
    _announcement = widget.currentAnnouncement;
    _controller = TextEditingController(text: _announcement ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('公告内容不能为空')),
      );
      return;
    }
    setState(() => _isPublishing = true);
    try {
      await widget.repository.updateAnnouncement(widget.conversationId, text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('群公告已更新')),
        );
        Navigator.of(context).pop(text);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('群公告'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (widget.isOwner && !_isEditing)
            TextButton(
              onPressed: () => setState(() {
                _isEditing = true;
                _controller.text = _announcement ?? '';
              }),
              child: const Text('编辑', style: TextStyle(color: Color(0xFF3B82F6))),
            ),
          if (widget.isOwner && _isEditing)
            TextButton(
              onPressed: _isPublishing ? null : _publish,
              child: _isPublishing
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('发布', style: TextStyle(color: Color(0xFF3B82F6))),
            ),
        ],
      ),
      body: _isEditing ? _buildEditMode() : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    final hasAnnouncement = _announcement != null && _announcement!.isNotEmpty;

    if (!hasAnnouncement) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('暂无群公告', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
            if (widget.isOwner) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => setState(() => _isEditing = true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('发布群公告'),
              ),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _announcement!,
          style: const TextStyle(fontSize: 15, color: Color(0xFF333333), height: 1.6),
        ),
      ),
    );
  }

  Widget _buildEditMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: null,
          minLines: 8,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: '请输入群公告内容',
            hintStyle: TextStyle(color: Color(0xFFBBBBBB)),
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 15, color: Color(0xFF333333), height: 1.6),
        ),
      ),
    );
  }
}
