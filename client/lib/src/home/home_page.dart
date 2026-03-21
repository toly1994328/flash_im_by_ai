import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2; // 默认"我的"
  bool _hasShownPasswordHint = false;

  final _pages = const [
    Center(child: Text('暂无消息', style: TextStyle(color: Colors.grey))),
    Center(child: Text('暂无联系人', style: TextStyle(color: Colors.grey))),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // 延迟弹出密码设置引导
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPasswordHint());
  }

  void _checkPasswordHint() {
    if (_hasShownPasswordHint) return;
    final state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated && !state.hasPassword) {
      _hasShownPasswordHint = true;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('设置密码'),
          content: const Text('建议设置密码，方便下次快速登录'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('跳过'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2); // 切到"我的"
              },
              child: const Text('去设置'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '消息'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts_outlined), label: '通讯录'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}
