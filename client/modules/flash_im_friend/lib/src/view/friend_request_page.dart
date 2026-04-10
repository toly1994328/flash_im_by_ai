import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/friend.dart';
import '../logic/friend_cubit.dart';
import '../logic/friend_state.dart';

/// 好友申请页（TabBar：好友申请 / 我的申请）
class FriendRequestPage extends StatefulWidget {
  final VoidCallback? onAddFriendTap;
  const FriendRequestPage({super.key, this.onAddFriendTap});

  @override
  State<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final cubit = context.read<FriendCubit>();
    cubit.loadReceivedRequests();
    cubit.loadSentRequests();
    cubit.clearPendingCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('新的朋友'),
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: widget.onAddFriendTap,
            child: const Text('添加朋友', style: TextStyle(fontSize: 14)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3B82F6),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: '好友申请'),
            Tab(text: '我的申请'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReceivedTab(),
          _SentTab(),
        ],
      ),
    );
  }
}

class _ReceivedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendCubit, FriendState>(
      builder: (context, state) {
        if (state.receivedRequests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 56, color: Color(0xFFCCCCCC)),
                SizedBox(height: 12),
                Text('暂无收到的申请', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: state.receivedRequests.length,
          separatorBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(left: 68),
            child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF0F0F0)),
          ),
          itemBuilder: (_, index) {
            final req = state.receivedRequests[index];
            return Dismissible(
              key: ValueKey(req.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => context.read<FriendCubit>().deleteRequest(req.id),
              child: _ReceivedItem(request: req),
            );
          },
        );
      },
    );
  }
}

class _ReceivedItem extends StatelessWidget {
  final FriendRequest request;
  const _ReceivedItem({required this.request});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AvatarWidget(avatar: request.avatar, size: 44, borderRadius: 6),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.nickname,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                if (request.message != null && request.message!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(request.message!,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.read<FriendCubit>().rejectRequest(request.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const Text('拒绝', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () async {
              await context.read<FriendCubit>().acceptRequest(request.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已添加为好友'), duration: Duration(seconds: 2)),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('接受', style: TextStyle(fontSize: 13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendCubit, FriendState>(
      builder: (context, state) {
        if (state.sentRequests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.outbox_outlined, size: 56, color: Color(0xFFCCCCCC)),
                SizedBox(height: 12),
                Text('暂无发送的申请', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: state.sentRequests.length,
          separatorBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(left: 68),
            child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF0F0F0)),
          ),
          itemBuilder: (_, index) {
            final req = state.sentRequests[index];
            return Dismissible(
              key: ValueKey(req.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => context.read<FriendCubit>().deleteRequest(req.id),
              child: _SentItem(request: req),
            );
          },
        );
      },
    );
  }
}

class _SentItem extends StatelessWidget {
  final FriendRequest request;
  const _SentItem({required this.request});

  @override
  Widget build(BuildContext context) {
    final (statusText, statusColor) = switch (request.status) {
      1 => ('已通过', const Color(0xFF4CAF50)),
      2 => ('已拒绝', const Color(0xFFE53935)),
      _ => ('等待验证', const Color(0xFFF9A825)),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AvatarWidget(avatar: request.avatar, size: 44, borderRadius: 6),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.nickname,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                if (request.message != null && request.message!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(request.message!,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Text(statusText, style: TextStyle(fontSize: 13, color: statusColor)),
        ],
      ),
    );
  }
}
