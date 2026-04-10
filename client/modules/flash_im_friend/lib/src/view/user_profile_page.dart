import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/friend.dart';
import '../logic/friend_cubit.dart';
import 'send_request_page.dart';
import '../data/friend_repository.dart';

/// 陌生人资料页（搜索结果点击进入，展示详细资料）
class UserProfilePage extends StatelessWidget {
  final UserProfile profile;
  final FriendRepository repository;

  const UserProfilePage({
    super.key,
    required this.profile,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // 用户信息卡片
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarWidget(avatar: profile.avatar, size: 64, borderRadius: 8),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(profile.nickname,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('闪讯号：${profile.id}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 签名区域
          if (profile.signature != null && profile.signature!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('个性签名', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                  const SizedBox(height: 6),
                  Text(profile.signature!, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          // 添加到通讯录按钮
          Container(
            color: Colors.white,
            width: double.infinity,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SendRequestPage(
                    profile: profile,
                    repository: repository,
                    onSuccess: () {
                      try {
                        context.read<FriendCubit>().loadSentRequests();
                      } catch (_) {}
                    },
                  ),
                ));
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  '添加到通讯录',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
