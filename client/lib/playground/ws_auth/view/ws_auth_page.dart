import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import '../../auth/api/auth_api.dart';
import '../../auth/model/user_profile.dart';
import '../api/ws_auth_api.dart';

const _kPrimary = Color(0xFF3B82F6);

/// WebSocket + JWT 认证整合测试页（带底部导航）
class WsAuthPage extends StatefulWidget {
  const WsAuthPage({super.key});

  @override
  State<WsAuthPage> createState() => _WsAuthPageState();
}

class _WsAuthPageState extends State<WsAuthPage> {
  final AuthApi _authApi = AuthApi();
  final WsAuthApi _wsApi = WsAuthApi();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _loggedIn = false;
  UserProfile? _profile;
  int _tabIndex = 0;

  // 登录状态（与 login_page 一致）
  bool _smsSent = false;
  bool _smsLoading = false;
  bool _loginLoading = false;
  bool _agreed = false;
  int _countdown = 0;
  Timer? _timer;

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() { _countdown--; });
      if (_countdown <= 0) t.cancel();
    });
  }

  bool get _canSendSms => !_smsLoading && _countdown <= 0;

  Future<void> _sendSms() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 11 || !phone.startsWith('1')) {
      showToast('请输入正确的手机号');
      return;
    }
    setState(() { _smsLoading = true; });
    try {
      final code = await _authApi.sendSms(phone);
      _codeCtrl.text = code; // 模拟阶段自动填入
      _startCountdown();
      setState(() { _smsSent = true; _smsLoading = false; });
    } catch (e) {
      showToast('发送失败: $e');
      setState(() => _smsLoading = false);
    }
  }

  Future<void> _login() async {
    if (!_agreed) {
      showToast('请先同意用户协议');
      return;
    }
    setState(() { _loginLoading = true; });
    try {
      await _authApi.login(_phoneCtrl.text.trim(), _codeCtrl.text.trim());
      final profile = await _authApi.getProfile();
      setState(() {
        _loggedIn = true;
        _profile = profile;
        _loginLoading = false;
      });
    } catch (e) {
      showToast('登录失败，请检查验证码');
      setState(() => _loginLoading = false);
    }
  }

  void _logout() {
    _wsApi.disconnect();
    _authApi.logout();
    setState(() {
      _loggedIn = false;
      _profile = null;
      _tabIndex = 0;
      _smsSent = false;
      _agreed = false;
      _countdown = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wsApi.disconnect();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) return _buildLoginScaffold();

    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _ChatRoomTab(authApi: _authApi, wsApi: _wsApi, profile: _profile!),
          _ProfileTab(authApi: _authApi, profile: _profile!, onLogout: _logout),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (i) => setState(() => _tabIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFF7F7F7),
          selectedItemColor: const Color(0xFF07C160),
          unselectedItemColor: const Color(0xFF999999),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          iconSize: 24,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: '聊天'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: '我'),
          ],
        ),
      ),
    );
  }

  // ========== 登录界面（与 login_page.dart 保持一致） ==========

  Widget _buildLoginScaffold() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 24),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'FLASH IM',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                const SizedBox(height: 6),
                Text(
                  '即时通信练习场',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], letterSpacing: 4),
                ),
                const SizedBox(height: 56),

                // 手机号
                _buildInputRow(
                  label: '+86',
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: '请输入手机号',
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 验证码
                _buildInputRow(
                  label: '验证码',
                  trailing: GestureDetector(
                    onTap: _canSendSms ? _sendSms : null,
                    child: Text(
                      _countdown > 0 ? '${_countdown}s' : (_smsSent ? '重新发送' : '获取验证码'),
                      style: TextStyle(
                        fontSize: 14,
                        color: _canSendSms ? _kPrimary : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  child: TextField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: '请输入验证码',
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 协议勾选
                GestureDetector(
                  onTap: () => setState(() => _agreed = !_agreed),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CheckIcon(checked: _agreed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            children: const [
                              TextSpan(text: '登录即代表您同意'),
                              TextSpan(text: '《用户协议》', style: TextStyle(color: _kPrimary)),
                              TextSpan(text: '和'),
                              TextSpan(text: '《隐私政策》', style: TextStyle(color: _kPrimary)),
                              TextSpan(text: '，未注册绑定的手机号验证成功后将自动注册'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 登录按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: (_loginLoading || !_smsSent) ? null : _login,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: _loginLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('登录', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow({required String label, required Widget child, Widget? trailing}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Container(
            width: 1, height: 20,
            margin: const EdgeInsets.only(right: 12),
            color: _kPrimary.withValues(alpha: 0.4),
          ),
          Expanded(child: child),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

/// 自定义圆角勾选图标（与 login_page 一致）
class _CheckIcon extends StatelessWidget {
  final bool checked;
  const _CheckIcon({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14, height: 14,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: checked ? _kPrimary : Colors.transparent,
        border: Border.all(color: checked ? _kPrimary : Colors.grey[400]!, width: 1.2),
      ),
      child: checked ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
    );
  }
}

// ========== 聊天室 Tab（微信风格） ==========

class _ChatRoomTab extends StatefulWidget {
  final AuthApi authApi;
  final WsAuthApi wsApi;
  final UserProfile profile;
  const _ChatRoomTab({required this.authApi, required this.wsApi, required this.profile});

  @override
  State<_ChatRoomTab> createState() => _ChatRoomTabState();
}

class _ChatRoomTabState extends State<_ChatRoomTab> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMsg> _messages = [];
  WsAuthStatus _wsStatus = WsAuthStatus.disconnected;
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    final token = widget.authApi.token;
    if (token == null) return;
    setState(() => _wsStatus = WsAuthStatus.connecting);

    _wsSub = widget.wsApi.connectChatRoom(token).listen(
      (data) {
        final type = data['type'] as String?;
        if (type == 'auth_ok') {
          setState(() => _wsStatus = WsAuthStatus.authenticated);
        } else if (type == 'auth_fail' || type == 'auth_timeout') {
          setState(() => _wsStatus = WsAuthStatus.disconnected);
          _addSystem('${data['message']}');
        } else if (type == 'message') {
          final uid = data['user_id'];
          if (uid == widget.profile.userId) return;
          final nick = data['nickname'] ?? '';
          final text = data['text'] ?? '';
          final avatar = data['avatar'] ?? '';
          _addMsg(text, false, nickname: nick, avatar: avatar);
        } else if (type == 'join') {
          final nick = data['nickname'] ?? '';
          if (nick != widget.profile.nickname) {
            _addSystem('$nick 加入了聊天室');
          }
        } else if (type == 'leave') {
          final nick = data['nickname'] ?? '';
          if (nick != widget.profile.nickname) {
            _addSystem('$nick 离开了聊天室');
          }
        }
      },
      onDone: () {
        setState(() => _wsStatus = WsAuthStatus.disconnected);
        _addSystem('连接已断开');
      },
      onError: (e) {
        setState(() => _wsStatus = WsAuthStatus.disconnected);
        _addSystem('连接错误');
      },
    );
  }

  void _sendMsg() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _wsStatus != WsAuthStatus.authenticated) return;
    widget.wsApi.send(text);
    _addMsg(text, true, nickname: widget.profile.nickname, avatar: widget.profile.avatar);
    _msgCtrl.clear();
  }

  void _addMsg(String text, bool isMe, {required String nickname, required String avatar}) {
    setState(() => _messages.add(_ChatMsg(text: text, isMe: isMe, nickname: nickname, avatar: avatar)));
    _scrollToBottom();
  }

  void _addSystem(String text) {
    setState(() => _messages.add(_ChatMsg(text: text, isSystem: true)));
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
    _wsSub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('聊天室'),
        centerTitle: true,
        backgroundColor: const Color(0xFFEDEDED),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFEDEDED),
      body: Column(
        children: [
          _buildStatusBar(),
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    if (_wsStatus == WsAuthStatus.authenticated) return const SizedBox.shrink();
    final (text, color) = switch (_wsStatus) {
      WsAuthStatus.disconnected => ('连接已断开，点击重连', Colors.red),
      WsAuthStatus.connecting => ('正在连接...', Colors.orange),
      WsAuthStatus.authenticating => ('正在认证...', Colors.orange),
      WsAuthStatus.authenticated => ('', Colors.green),
    };
    return GestureDetector(
      onTap: _wsStatus == WsAuthStatus.disconnected ? _connect : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        color: color.withValues(alpha: 0.15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_wsStatus != WsAuthStatus.disconnected)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: color)),
              ),
            if (_wsStatus == WsAuthStatus.disconnected)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.refresh, size: 14, color: color),
              ),
            Text(text, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return const Center(child: Text('暂无消息', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _WeChatBubble(msg: _messages[i]),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        border: Border(top: BorderSide(color: Color(0xFFD9D9D9), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 36),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  style: const TextStyle(fontSize: 15),
                  maxLines: 4,
                  minLines: 1,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendMsg(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: _wsStatus == WsAuthStatus.authenticated ? _sendMsg : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF07C160),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('发送', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== 我的 Tab（微信风格） ==========

class _ProfileTab extends StatelessWidget {
  final AuthApi authApi;
  final UserProfile profile;
  final VoidCallback onLogout;
  const _ProfileTab({required this.authApi, required this.profile, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        title: const Text('我'),
        centerTitle: true,
        backgroundColor: const Color(0xFFEDEDED),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // 头像卡片
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(profile.avatar, width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64, height: 64, color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 32, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('ID: ${profile.userId}', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 信息列表
          _buildCell(icon: Icons.phone, title: '手机号', value: profile.phone),
          _buildDivider(),
          _buildCell(icon: Icons.vpn_key, title: 'Token', value: _truncateToken(authApi.token)),

          const SizedBox(height: 8),

          // 退出登录
          GestureDetector(
            onTap: onLogout,
            child: Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: const Text('退出登录', style: TextStyle(fontSize: 16, color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  String _truncateToken(String? token) {
    if (token == null || token.length < 30) return token ?? '';
    return '${token.substring(0, 15)}...${token.substring(token.length - 10)}';
  }

  Widget _buildCell({required IconData icon, required String title, required String value}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF07C160)),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 15)),
          const Spacer(),
          Flexible(
            child: Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 48),
      child: const Divider(height: 0.5, thickness: 0.5),
    );
  }
}

// ========== 消息模型 & 微信风格气泡 ==========

class _ChatMsg {
  final String text;
  final bool isMe;
  final bool isSystem;
  final String? nickname;
  final String? avatar;
  final DateTime time;

  _ChatMsg({required this.text, this.isMe = false, this.isSystem = false, this.nickname, this.avatar})
      : time = DateTime.now();
}

/// 微信风格消息气泡：头像 + 昵称 + 气泡
class _WeChatBubble extends StatelessWidget {
  final _ChatMsg msg;
  const _WeChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    if (msg.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFCECECE),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(msg.text, style: const TextStyle(fontSize: 11, color: Colors.white)),
          ),
        ),
      );
    }

    final avatar = CircleAvatar(
      radius: 20,
      backgroundImage: msg.avatar != null ? NetworkImage(msg.avatar!) : null,
      backgroundColor: Colors.grey[300],
      child: msg.avatar == null ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
    );

    // 气泡颜色：自己绿色，别人白色（微信风格）
    final bubbleColor = msg.isMe ? const Color(0xFF95EC69) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!msg.isMe) avatar,
          if (!msg.isMe) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!msg.isMe && msg.nickname != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Text(msg.nickname!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(msg.text, style: const TextStyle(fontSize: 15, height: 1.3)),
                ),
              ],
            ),
          ),
          if (msg.isMe) const SizedBox(width: 8),
          if (msg.isMe) avatar,
        ],
      ),
    );
  }
}
