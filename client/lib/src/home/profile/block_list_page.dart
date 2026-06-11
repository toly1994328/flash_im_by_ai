import 'package:dio/dio.dart';
import 'package:flash_shared/flash_shared.dart' show AvatarWidget;
import 'package:flutter/material.dart';

/// 黑名单页面（微信风格）
class BlockListPage extends StatefulWidget {
  final Dio dio;
  const BlockListPage({super.key, required this.dio});

  @override
  State<BlockListPage> createState() => _BlockListPageState();
}

class _BlockListPageState extends State<BlockListPage> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final Response<dynamic> res = await widget.dio.get('/api/blocks');
      final List<dynamic> data = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
      if (!mounted) return;
      setState(() { _list = data.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unblock(int index) async {
    final Map<String, dynamic> item = _list[index];
    final String nickname = item['nickname'] as String? ?? '';
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('取消拉黑', style: TextStyle(fontSize: 17)),
        content: Text('确定将 $nickname 移出黑名单？移出后对方可以重新给你发消息。',
          style: const TextStyle(fontSize: 15, color: Color(0xFF666666))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Color(0xFF999999)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定', style: TextStyle(color: Color(0xFF3B82F6)))),
        ],
      ),
    );
    if (confirm != true) return;
    await widget.dio.delete('/api/blocks/${item['user_id']}');
    if (!mounted) return;
    setState(() => _list.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已将 $nickname 移出黑名单'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('黑名单'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('暂无拉黑用户', style: TextStyle(fontSize: 15, color: Color(0xFF999999))),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      child: ListView.separated(
        itemCount: _list.length,
        separatorBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(left: 68),
          child: Divider(height: 0.5, thickness: 0.5, color: Colors.grey[200]),
        ),
        itemBuilder: (_, int i) => _buildItem(i),
      ),
    );
  }

  Widget _buildItem(int index) {
    final Map<String, dynamic> item = _list[index];
    final String nickname = item['nickname'] as String? ?? '';
    final String? avatar = item['avatar'] as String?;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AvatarWidget(avatar: avatar, size: 44, borderRadius: 6),
          const SizedBox(width: 12),
          Expanded(child: Text(nickname, style: const TextStyle(fontSize: 16, color: Color(0xFF333333)))),
          GestureDetector(
            onTap: () => _unblock(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDDDDD)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('移除', style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
            ),
          ),
        ],
      ),
    );
  }
}
