/// Flash IM 核心模块
///
/// WebSocket 通信、Protobuf 协议、连接管理。
library;

// data
export 'src/data/proto/ws.pb.dart';
export 'src/data/proto/ws.pbenum.dart';
export 'src/data/proto/message.pb.dart';
export 'src/data/proto/message.pbenum.dart';
export 'src/data/im_config.dart';

// logic
export 'src/logic/ws_client.dart';

// view
export 'src/view/ws_status_indicator.dart';
