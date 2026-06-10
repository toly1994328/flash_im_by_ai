/// Flash IM 本地缓存模块
///
/// 抽象存储接口 + 纯 Dart 模型 + 同步引擎 + 文件缓存管理。
/// 上层模块只依赖 LocalStore 接口和纯 Dart 模型。
/// drift 实现在独立包 flash_im_cache_drift 中。
library;

// 纯 Dart 模型（无 ORM 依赖）
export 'src/models/cached_message.dart';
export 'src/models/cached_conversation.dart';
export 'src/models/cached_friend.dart';

// 抽象接口
export 'src/local_store.dart';

// 空实现（无本地缓存，所有数据走网络）
export 'src/empty_local_store.dart';

// 同步引擎
export 'src/sync_engine.dart';

// 文件缓存管理器
export 'src/file_cache_manager.dart';
export 'src/file_cache_manager_impl.dart';
export 'src/noop_file_cache_manager.dart';
