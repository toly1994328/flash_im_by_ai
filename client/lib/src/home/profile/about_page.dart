import 'package:flutter/material.dart';

/// 关于闪讯页面（微信风格）
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('关于闪讯'),
        backgroundColor: const Color(0xFFEDEDED),
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 60),
          // Logo + 名称 + 版本
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/images/logo.png', width: 72, height: 72),
                ),
                const SizedBox(height: 16),
                const Text(
                  '闪讯 IM',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Version 0.24.0',
                  style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          // 功能介绍
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '连接此刻，不止于此',
                  style: TextStyle(fontSize: 15, color: Color(0xFF333333), fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),
                Text(
                  '闪讯是一款全栈即时通讯应用，支持文字、语音、图片、视频、文件消息，'
                  '好友管理、群聊、消息搜索等功能。',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.6),
                ),
                SizedBox(height: 16),
                Text(
                  '技术栈：Rust (Axum) + Flutter + PostgreSQL + WebSocket',
                  style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          const Spacer(),
          // 底部版权
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              children: [
                Text(
                  '© 2026 闪讯团队',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Made with ❤️ and AI',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
