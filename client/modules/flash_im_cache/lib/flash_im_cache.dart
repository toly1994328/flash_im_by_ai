/// Flash IM 本地缓存模块
///
/// 抽象存储接口 + drift 实现 + 同步引擎。
/// 上层模块只依赖 LocalStore 接口和纯 Dart 模型。
library;

// 纯 Dart 模型（无 ORM 依赖）
export 'src/models/cached_message.dart';
export 'src/models/cached_conversation.dart';
export 'src/models/cached_friend.dart';

// 抽象接口
export 'src/local_store.dart';

// drift 实现（只在 main.dart 初始化时用）
export 'src/drift/drift_local_store.dart';

// 同步引擎
export 'src/sync_engine.dart';
