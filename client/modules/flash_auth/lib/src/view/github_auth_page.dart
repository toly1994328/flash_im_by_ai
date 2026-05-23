import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _githubClientId = 'Ov23liTOF9mrGIndUYD9';
const _redirectUri = 'http://localhost/callback';
const _authUrl = 'https://github.com/login/oauth/authorize'
    '?client_id=$_githubClientId'
    '&redirect_uri=$_redirectUri'
    '&scope=read:user';

/// GitHub OAuth 授权页面
///
/// 内嵌 WebView 加载 GitHub 授权页，拦截回调 URL 提取 code。
/// 返回值：code 字符串，用户取消则返回 null。
class GitHubAuthPage extends StatefulWidget {
  const GitHubAuthPage({super.key});

  @override
  State<GitHubAuthPage> createState() => _GitHubAuthPageState();
}

class _GitHubAuthPageState extends State<GitHubAuthPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('[GitHubAuth] 加载授权 URL: $_authUrl');
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          debugPrint('[GitHubAuth] 导航到: ${request.url}');
          if (request.url.startsWith(_redirectUri)) {
            final uri = Uri.parse(request.url);
            final code = uri.queryParameters['code'];
            debugPrint('[GitHubAuth] 拦截到 code: $code');
            Navigator.of(context).pop(code);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageFinished: (url) {
          debugPrint('[GitHubAuth] 页面加载完成: $url');
          if (mounted) setState(() => _isLoading = false);
        },
        onWebResourceError: (error) {
          debugPrint('[GitHubAuth] 加载错误: ${error.description}');
        },
      ))
      ..loadRequest(Uri.parse(_authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GitHub 登录'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
