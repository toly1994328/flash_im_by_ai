import 'package:flash_im_cache/flash_im_cache.dart';

import 'message.dart';
import 'message_repository.dart';

/// 消息仓库抽象接口。
///
/// ChatCubit 依赖此接口而非具体实现，方便测试时注入 mock。
abstract class IMessageRepository {
  /// 获取消息列表（优先本地缓存，fallback HTTP）
  Future<List<Message>> getMessages(String conversationId, {int? beforeSeq, int limit = 50});

  /// 上传图片
  Future<ImageUploadResult> uploadImage(String filePath, {void Function(double)? onProgress});

  /// 上传视频
  Future<VideoUploadResult> uploadVideo(String filePath, String thumbPath, int durationMs, {int width, int height, void Function(double)? onProgress});

  /// 上传文件
  Future<FileUploadResult> uploadFile(String filePath, {void Function(double)? onProgress});

  /// 下载文件到本地
  Future<String> downloadFile(String url, String savePath, {void Function(double)? onProgress});

  /// 消息撤回
  Future<void> recallMessage(String conversationId, String messageId);

  /// 转发消息
  Future<Map<String, dynamic>> forwardMessage({required String sourceConvId, required List<String> messageIds, required String targetConvId, required String forwardType});

  /// 查询置顶列表
  Future<List<Map<String, dynamic>>> getPinnedMessages(String conversationId);

  /// 置顶消息
  Future<Map<String, dynamic>> pinMessage(String conversationId, String messageId);

  /// 取消置顶
  Future<void> unpinMessage(String conversationId, String pinId);

  /// 获取会话已读位置
  Future<Map<String, int>> getReadSeq(String conversationId);

  /// 本地缓存访问
  LocalStore? get store;
}
