import 'package:flutter/material.dart';

import '../logic/ws_client.dart';

/// 连接状态指示器
///
/// 监听 WsClient 的 stateStream，在非 authenticated 状态下
/// 显示一条全宽横条提示当前连接状态。authenticated 时完全隐藏。
class WsStatusIndicator extends StatelessWidget {
  final Stream<WsConnectionState> stateStream;
  final WsConnectionState initialState;
  final VoidCallback? onTapReconnect;

  const WsStatusIndicator({
    super.key,
    required this.stateStream,
    required this.initialState,
    this.onTapReconnect,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WsConnectionState>(
      stream: stateStream,
      initialData: initialState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? WsConnectionState.disconnected;
        if (state == WsConnectionState.authenticated) {
          return const SizedBox.shrink();
        }

        final (text, color) = switch (state) {
          WsConnectionState.disconnected => ('连接已断开，点击重连', Colors.red),
          WsConnectionState.connecting => ('正在连接...', Colors.orange),
          WsConnectionState.authenticating => ('正在认证...', Colors.orange),
          WsConnectionState.authenticated => ('', Colors.green),
        };

        return GestureDetector(
          onTap: state == WsConnectionState.disconnected ? onTapReconnect : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: color.withValues(alpha: 0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state == WsConnectionState.disconnected)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.refresh, size: 14, color: color),
                  ),
                if (state != WsConnectionState.disconnected)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
                    ),
                  ),
                Text(text, style: TextStyle(fontSize: 12, color: color)),
              ],
            ),
          ),
        );
      },
    );
  }
}
