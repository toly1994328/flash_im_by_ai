import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/logic/auth/auth_cubit.dart';
import '../../auth/logic/auth/auth_state.dart';
import '../../auth/data/repository/auth_repository.dart';
import '../profile/profile_page.dart';
import '../profile/set_password_page.dart';

class HomePage extends StatefulWidget {
  final AuthRepository authRepository;

  const HomePage({super.key, required this.authRepository});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _hasShownPasswordGuide = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPasswordGuide();
    });
  }

  void _checkPasswordGuide() {
    final state = context.read<AuthCubit>().state;
    if (state.status == AuthStatus.authenticated && !state.hasPassword && !_hasShownPasswordGuide) {
      _hasShownPasswordGuide = true;
      _showPasswordGuideDialog();
    }
  }

  void _showPasswordGuideDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.white,
        title: const Text('设置密码'),
        content: const Text('建议设置密码，方便下次快速登录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('跳过'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<AuthCubit>(),
                    child: SetPasswordPage(
                      authRepository: widget.authRepository,
                      hasPassword: false,
                    ),
                  ),
                ),
              );
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const Center(child: Text('暂无消息', style: TextStyle(fontSize: 16, color: Colors.grey))),
      const Center(child: Text('暂无联系人', style: TextStyle(fontSize: 16, color: Colors.grey))),
      ProfilePage(authRepository: widget.authRepository),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '消息'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts_outlined), label: '通讯录'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}
