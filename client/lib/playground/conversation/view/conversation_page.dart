import 'package:flutter/material.dart';
import '../api/conversation_api.dart';
import '../model/conversation.dart';
import 'conversation_tile.dart';

/// 会话列表页面
class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  late Future<List<Conversation>> _future;

  @override
  void initState() {
    super.initState();
    _future = ConversationApi().getList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0.5,
        centerTitle: true,
        title: const Text('微信', style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<Conversation>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('请求失败: ${snapshot.error}'));
          }
          final list = snapshot.data!;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) => ConversationTile(conversation: list[index]),
          );
        },
      ),
    );
  }
}
