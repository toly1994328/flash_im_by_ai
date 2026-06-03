/// Flash IM 本地缓存 drift 实现
///
/// 提供 DriftLocalStore，基于 drift + SQLite。
/// 仅在 main.dart 初始化时引用，上层模块只依赖 flash_im_cache 的 LocalStore 接口。
library;

export 'src/drift_local_store.dart';
