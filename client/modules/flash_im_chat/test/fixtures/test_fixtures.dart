import 'package:flash_im_chat/src/data/message.dart';
import 'package:flash_im_chat/src/data/message_repository.dart';

/// 测试数据工厂。
///
/// 使用和生产代码相同的模型类构造测试数据，
/// 模型字段变更时工厂方法编译报错，强制同步更新。
class TestFixtures {
  static const defaultConvId = 'conv_test_1';
  static const defaultUserId = 'user_1';
  static const defaultUserName = '测试用户';
  static const defaultPeerId = 'user_2';
  static const defaultPeerName = '对方用户';

  /// 构造单条消息
  static Message message({
    String id = 'msg_1',
    String conversationId = defaultConvId,
    String senderId = defaultUserId,
    String senderName = defaultUserName,
    String? senderAvatar,
    int seq = 1,
    MessageType type = MessageType.text,
    String content = 'hello',
    MessageStatus status = MessageStatus.sent,
    Map<String, dynamic>? extra,
    DateTime? createdAt,
  }) =>
      Message(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        seq: seq,
        type: type,
        content: content,
        status: status,
        extra: extra,
        createdAt: createdAt ?? DateTime(2026, 1, 1),
      );

  /// 构造消息列表（seq 从 1 递增）
  static List<Message> messageList({
    int count = 10,
    String conversationId = defaultConvId,
    String senderId = defaultPeerId,
    String senderName = defaultPeerName,
  }) =>
      List.generate(
        count,
        (i) => message(
          id: 'msg_$i',
          conversationId: conversationId,
          senderId: senderId,
          senderName: senderName,
          seq: i + 1,
          content: '消息 $i',
        ),
      );

  /// 构造图片上传结果
  static ImageUploadResult imageUploadResult({
    String originalUrl = '/uploads/original/test.jpg',
    String thumbnailUrl = '/uploads/thumb/test.webp',
    int width = 800,
    int height = 600,
    int size = 102400,
    String format = 'jpg',
  }) =>
      ImageUploadResult(
        originalUrl: originalUrl,
        thumbnailUrl: thumbnailUrl,
        width: width,
        height: height,
        size: size,
        format: format,
      );

  /// 构造视频上传结果
  static VideoUploadResult videoUploadResult({
    String videoUrl = '/uploads/video/test.mp4',
    String thumbnailUrl = '/uploads/thumb/test.jpg',
    int durationMs = 5000,
    int width = 1920,
    int height = 1080,
    int fileSize = 1048576,
  }) =>
      VideoUploadResult(
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        durationMs: durationMs,
        width: width,
        height: height,
        fileSize: fileSize,
      );

  /// 构造文件上传结果
  static FileUploadResult fileUploadResult({
    String fileUrl = '/uploads/file/test.pdf',
    String fileName = 'test.pdf',
    int fileSize = 204800,
    String fileType = 'pdf',
  }) =>
      FileUploadResult(
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        fileType: fileType,
      );
}
