import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'firework/firework_page.dart';
import 'conversation/view/conversation_page.dart';
import 'heartbeat/view/heartbeat_page.dart';
import 'auth/view/login_page.dart';
import 'ws_auth/view/ws_auth_page.dart';

void main() {
  runApp(
    OKToast(
      child: const MaterialApp(
        title: '开发游乐场',
        debugShowCheckedModeBanner: false,
        home: PlaygroundPage(),
      ),
    ),
  );
}

/// 开发游乐场入口（仅 debug 模式可见）
class PlaygroundPage extends StatelessWidget {
  const PlaygroundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 开发游乐场'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PlaygroundItem(
            icon: '🎆',
            title: '烟花秀',
            subtitle: '粒子系统 & Canvas 绑定练习',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FireworkPage())),
          ),
          _PlaygroundItem(
            icon: '💬',
            title: '会话列表',
            subtitle: '网络请求 & 列表渲染练习',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ConversationPage())),
          ),
          _PlaygroundItem(
            icon: '💓',
            title: '心跳通信',
            subtitle: 'WebSocket 双向实时通信练习',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HeartbeatPage())),
          ),
          _PlaygroundItem(
            icon: '🔐',
            title: '用户认证',
            subtitle: '登录流程 & Token 鉴权练习',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LoginPage())),
          ),
          _PlaygroundItem(
            icon: '🔗',
            title: '认证通信',
            subtitle: 'WebSocket + JWT 身份认证整合练习',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const WsAuthPage())),
          ),
        ],
      ),
    );
  }
}

class _PlaygroundItem extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PlaygroundItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 28)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
