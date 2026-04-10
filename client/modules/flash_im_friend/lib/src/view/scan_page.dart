import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/friend_repository.dart';
import 'user_profile_page.dart';

/// 扫码页：扫描二维码添加好友
///
/// 识别 flashim://user/{id} 格式，跳转用户资料页
class ScanPage extends StatefulWidget {
  final FriendRepository repository;

  const ScanPage({super.key, required this.repository});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final value = barcode.rawValue!;
    final uri = Uri.tryParse(value);

    // 匹配 flashim://user/{id}
    if (uri == null || uri.scheme != 'flashim' || uri.host != 'user' || uri.pathSegments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法识别的二维码'), duration: Duration(seconds: 2)),
      );
      return;
    }

    final userId = uri.pathSegments.first;
    _processing = true;
    _controller.stop();
    _fetchAndNavigate(userId);
  }

  Future<void> _fetchAndNavigate(String userId) async {
    // 全屏 loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final profile = await widget.repository.getUserProfile(userId);
      if (!mounted) return;
      Navigator.pop(context); // 关闭 loading
      // 用 pushReplacement 替换扫码页，避免 pop+push 双动画
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => UserProfilePage(
          profile: profile,
          repository: widget.repository,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 关闭 loading
      setState(() => _processing = false);
      _controller.start();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取用户信息失败: $e'), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('扫一扫'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // 扫描框提示
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // 底部提示
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              '将二维码放入框内，即可自动扫描',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
