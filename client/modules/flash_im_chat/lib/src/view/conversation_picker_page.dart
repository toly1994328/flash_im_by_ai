import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flash_shared/flash_shared.dart';

/// 会话选择器：转发时选择目标会话
///
/// 默认单选（点击直接返回），右上角可切换多选模式。
class ConversationPickerPage extends StatefulWidget {
  final String? excludeConvId;
  final Dio dio;
  final String? baseUrl;
  final Widget? previewWidget; // 转发确认弹窗里的消息预览
  final WidgetBuilder? previewBuilder; // 延迟构建预览

  const ConversationPickerPage({
    super.key,
    this.excludeConvId,
    required this.dio,
    this.baseUrl,
    this.previewWidget,
    this.previewBuilder,
  });

  @override
  State<ConversationPickerPage> createState() => _ConversationPickerPageState();
}

class _ConversationPickerPageState extends State<ConversationPickerPage> {
  List<SelectableMember> _members = [];
  bool _loading = true;
  bool _multiSelect = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final res = await widget.dio.get('/conversations', queryParameters: {'limit': 100});
      final List data = res.data as List;
      final convs = data
          .cast<Map<String, dynamic>>()
          .where((c) => c['id'] != widget.excludeConvId)
          .toList();

      setState(() {
        _members = convs.map((c) {
          final name = c['name'] ?? c['peer_nickname'] ?? '未知';
          final avatar = c['avatar'] ?? c['peer_avatar'];
          return SelectableMember(
            id: c['id'] as String,
            nickname: name as String,
            avatar: avatar as String?,
            letter: PinyinUtil.getFirstLetter(name as String),
          );
        }).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _toggleMode() {
    setState(() => _multiSelect = !_multiSelect);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('选择会话', style: TextStyle(fontSize: 16)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF333333),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return MemberPickerPage(
      key: ValueKey(_multiSelect),
      members: _members,
      title: _multiSelect ? '多选转发' : '选择会话',
      confirmLabel: '转发',
      showIndexBar: false,
      selectMode: _multiSelect ? PickerSelectMode.multi : PickerSelectMode.single,
      actions: [
        TextButton(
          onPressed: _toggleMode,
          child: Text(
            _multiSelect ? '单选' : '多选',
            style: const TextStyle(fontSize: 14, color: Color(0xFF3B82F6)),
          ),
        ),
      ],
      onConfirmAsync: (result) async {
        final names = result.allIds.map((id) {
          final m = _members.where((m) => m.id == id).firstOrNull;
          return m?.nickname ?? '未知';
        }).join('、');

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('确认转发', style: TextStyle(fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('发送给：$names', style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
                if (widget.previewBuilder != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: widget.previewBuilder!(context),
                  ),
                ] else if (widget.previewWidget != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: widget.previewWidget!,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('取消', style: TextStyle(color: Color(0xFF999999))),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('发送', style: TextStyle(color: Color(0xFF3B82F6))),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
    );
  }

}
