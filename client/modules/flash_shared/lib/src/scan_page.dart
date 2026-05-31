import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// 通用扫码页，扫到不同 scheme 通过回调分发
///
/// 支持的 scheme：
/// - flashim://user/{id} → onUserScanned
/// - flashim://scan/{token} → onScanLogin
class ScanPage extends StatefulWidget {
  /// flashim://user/{id} 回调
  final void Function(String userId)? onUserScanned;

  /// flashim://scan/{token} 回调
  final void Function(String scanToken)? onScanLogin;

  const ScanPage({
    super.key,
    this.onUserScanned,
    this.onScanLogin,
  });

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
    debugPrint('[ScanPage] scanned: $value');
    final uri = Uri.tryParse(value);
    debugPrint('[ScanPage] parsed uri: $uri, scheme: ${uri?.scheme}, host: ${uri?.host}, segments: ${uri?.pathSegments}');
    if (uri == null || uri.scheme != 'flashim') {
      _showError('无法识别的二维码');
      return;
    }

    // flashim://scan/{token}
    if (uri.host == 'scan' && uri.pathSegments.isNotEmpty) {
      if (widget.onScanLogin == null) {
        _showError('当前不支持扫码登录');
        return;
      }
      _processing = true;
      _controller.stop();
      widget.onScanLogin!(uri.pathSegments.first);
      return;
    }

    // flashim://user/{id}
    if (uri.host == 'user' && uri.pathSegments.isNotEmpty) {
      if (widget.onUserScanned == null) {
        _showError('当前不支持添加好友');
        return;
      }
      _processing = true;
      _controller.stop();
      widget.onUserScanned!(uri.pathSegments.first);
      return;
    }

    _showError('无法识别的二维码');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
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
