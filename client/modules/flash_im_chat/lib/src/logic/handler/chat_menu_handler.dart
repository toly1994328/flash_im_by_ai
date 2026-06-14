import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart' show MemberPickerResult;
import 'package:fx_env/fx_env.dart';
import 'package:fx_logger/fx_logger.dart';
import 'package:tolyui_feedback_modal/tolyui_feedback_modal.dart';

import '../../data/message.dart';
import '../../data/message_repository.dart';
import '../../view/bubble/image_bubble.dart';
import '../../view/bubble/video_bubble.dart';
import '../../view/bubble/file_bubble.dart';
import '../../view/bubble/text_bubble.dart';
import '../../view/picker/conversation_picker_page.dart';
import '../../view/menu/message_action_menu.dart';
import '../../view/info/report_sheet.dart';
import '../chat_cubit.dart';
import '../chat_state.dart';
import 'chat_media_handler.dart';

/// 菜单事件分发（logic 层）
/// 统一处理桌面右键 + 移动端长按的 MenuAction
class ChatMenuHandler {
  final ChatCubit _cubit;
  final ChatMediaHandler _media;
  final String? baseUrl;
  final String conversationId;
  final MessageRepository Function(BuildContext) _repositoryGetter;

  final FxLog _log = FxLog('ChatMenu');

  ChatMenuHandler({
    required ChatCubit cubit,
    required ChatMediaHandler media,
    required this.conversationId,
    required MessageRepository Function(BuildContext) repositoryGetter,
    this.baseUrl,
  })  : _cubit = cubit,
        _media = media,
        _repositoryGetter = repositoryGetter;

  /// 统一处理 MenuAction
  void handle(BuildContext context, Message msg, bool isMe, MenuAction action) {
    switch (action) {
      case MenuAction.copy:
        _cubit.copyMessage(msg.content);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已复制'), duration: Duration(seconds: 1)),
        );
      case MenuAction.reply:
        _cubit.setReplyTo(msg);
      case MenuAction.recall:
        _cubit.recallMessage(msg.id);
      case MenuAction.delete:
        _confirmDeleteMessage(context, msg.id);
      case MenuAction.forward:
        _log.d('opening forward picker...');
        _forwardMessage(context, msg);
      case MenuAction.pin:
        _cubit.pinMessage(msg.id);
      case MenuAction.unpin:
        final String? pinId = _getPinId(msg.id);
        if (pinId != null) _cubit.unpinMessage(pinId);
      case MenuAction.multiSelect:
        _cubit.enterMultiSelect(msg.id);
      case MenuAction.openFolder:
        _media.openFileFolder(msg);
      case MenuAction.saveAs:
        _media.saveFileAs(msg);
      case MenuAction.report:
        _reportMessage(context, msg);
    }
  }

  // ─── 私有辅助方法 ───

  bool isMessagePinned(String messageId) {
    final ChatState s = _cubit.state;
    if (s is! ChatLoaded) return false;
    return s.pinnedMessages.any((p) => p.messageId == messageId);
  }

  String? _getPinId(String messageId) {
    final ChatState s = _cubit.state;
    if (s is! ChatLoaded) return null;
    final pin = s.pinnedMessages.where((p) => p.messageId == messageId).firstOrNull;
    return pin?.pinId;
  }

  void _confirmDeleteMessage(BuildContext context, String messageId) {
    showTolyPopPicker<bool>(
      context: context,
      title: const Text('确定删除这条消息？'),
      tasks: [
        TolyMenuItem(
          info: '删除',
          content: const Text('删除', style: TextStyle(color: Color(0xFFFF4D4F), fontSize: 16)),
          task: () {
            _cubit.deleteMessage(messageId);
            return true;
          },
        ),
      ],
    );
  }

  void _reportMessage(BuildContext context, Message msg) {
    final MessageRepository repository = _repositoryGetter(context);
    ReportSheet.show(
      context: context,
      targetId: msg.id,
      targetType: 0,
      onSubmit: (int reason, String? description) async {
        final Map<String, dynamic> body = {
          'target_type': 0,
          'target_id': msg.id,
          'reason': reason,
          'description': ?description,
        };
        await repository.dio.post('/api/reports', data: body);
      },
    );
  }

  Future<void> _forwardMessage(BuildContext context, Message msg) async {
    final MessageRepository repository = _repositoryGetter(context);
    MemberPickerResult? result;

    if (kApp.isDesktop) {
      final double screenHeight = MediaQuery.of(context).size.height;
      final double dialogHeight = (screenHeight * 0.8).clamp(0.0, 800.0);
      result = await showDialog<MemberPickerResult>(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 420,
              height: dialogHeight,
              child: ConversationPickerPage(
                excludeConvId: conversationId,
                dio: repository.dio,
                previewBuilder: (_) => _buildForwardPreview(msg),
              ),
            ),
          ),
        ),
      );
    } else {
      result = await Navigator.of(context).push<MemberPickerResult>(
        MaterialPageRoute(
          builder: (_) => ConversationPickerPage(
            excludeConvId: conversationId,
            dio: repository.dio,
            previewBuilder: (_) => _buildForwardPreview(msg),
          ),
        ),
      );
    }

    if (result != null && result.allIds.isNotEmpty && context.mounted) {
      for (final String targetConvId in result.allIds) {
        _cubit.forwardMessages(
          messageIds: [msg.id],
          targetConvId: targetConvId,
          forwardType: 'single',
        );
        if (targetConvId == conversationId) {
          _cubit.loadMessages();
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已转发'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  Widget _buildForwardPreview(Message msg) {
    final Widget bubble = switch (msg.type) {
      MessageType.image => ImageBubble(message: msg, baseUrl: baseUrl),
      MessageType.video => VideoBubble(message: msg, baseUrl: baseUrl),
      MessageType.file => FileBubble(message: msg, isMe: true),
      _ => TextBubble(message: msg, isMe: true),
    };
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: bubble,
    );
  }
}
