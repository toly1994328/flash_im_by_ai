import 'package:flutter/material.dart';
import '../api/ws_api.dart';
import '../model/ws_message.dart';

/// 心跳通信测试页
class HeartbeatPage extends StatefulWidget {
  const HeartbeatPage({super.key});

  @override
  State<HeartbeatPage> createState() => _HeartbeatPageState();
}

class _HeartbeatPageState extends State<HeartbeatPage> {
  final WsApi _ws = WsApi();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<WsMessage> _messages = [];
  WsStatus _status = WsStatus.disconnected;

  void _connect() {
    setState(() => _status = WsStatus.connecting);
    _ws.connect().listen(
      (data) {
        // ready 回调可能还没触发，收到第一条消息说明已连接
        if (_status != WsStatus.connected) {
          setState(() => _status = WsStatus.connected);
        }
        setState(() {
          _messages.add(WsMessage(text: data.toString(), isMe: false, time: DateTime.now()));
        });
        _scrollToBottom();
      },
      onDone: () => setState(() => _status = WsStatus.disconnected),
      onError: (_) => setState(() => _status = WsStatus.disconnected),
    );
  }

  void _disconnect() {
    _ws.disconnect();
    setState(() => _status = WsStatus.disconnected);
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _status != WsStatus.connected) return;
    _ws.send(text);
    setState(() {
      _messages.add(WsMessage(text: text, isMe: true, time: DateTime.now()));
    });
    _inputCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ws.disconnect();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💓 心跳通信'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [_buildStatusChip()],
      ),
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final (label, color) = switch (_status) {
      WsStatus.disconnected => ('已断开', Colors.grey),
      WsStatus.connecting => ('连接中', Colors.orange),
      WsStatus.connected => ('已连接', Colors.green),
    };
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Chip(
        label: Text(label, style: TextStyle(color: color, fontSize: 12)),
        backgroundColor: color.withValues(alpha: 0.1),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _status == WsStatus.disconnected ? _connect : null,
            icon: const Icon(Icons.link, size: 18),
            label: const Text('连接'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _status == WsStatus.connected ? _disconnect : null,
            icon: const Icon(Icons.link_off, size: 18),
            label: const Text('断开'),
          ),
          const Spacer(),
          if (_messages.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _messages.clear()),
              child: const Text('清空'),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text('点击「连接」开始测试', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _MessageBubble(message: _messages[i]),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -1))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              decoration: const InputDecoration(
                hintText: '输入消息...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _send,
            icon: const Icon(Icons.send, size: 20),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final WsMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final time = '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}:${message.time.second.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) Text('← ', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(message.text),
                  const SizedBox(height: 2),
                  Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ),
          if (isMe) Text(' →', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
