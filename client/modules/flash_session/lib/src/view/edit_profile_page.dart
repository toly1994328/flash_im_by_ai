import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flash_session/flash_session.dart';

/// 微信风格"个人资料"页面 — 列表式展示，点击行项编辑
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        final user = state.user;
        final seed = user != null && !user.hasCustomAvatar
            ? user.identiconSeed
            : '0';
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0.5,
            centerTitle: true,
            title: const Text('个人资料',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back_ios,
                  size: 18, color: Colors.black),
            ),
          ),
          body: ListView(
            children: [
              const SizedBox(height: 8),
              // 第一组：头像 + 名字
              _group([
                _avatarRow(context, seed),
                _row(
                  label: '名字',
                  value: user?.nickname ?? '',
                  onTap: () => _editField(
                    context,
                    title: '修改名字',
                    initial: user?.nickname ?? '',
                    maxLength: 50,
                    fieldName: 'nickname',
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              // 第二组：手机号 + ID
              _group([
                _row(label: '手机号', value: _maskPhone(user?.phone)),
                _row(label: '闪讯号', value: '${user?.userId ?? '-'}'),
              ]),
              const SizedBox(height: 8),
              // 第三组：签名
              _group([
                _row(
                  label: '签名',
                  value: (user?.signature.isNotEmpty == true)
                      ? user!.signature
                      : '未填写',
                  valueColor: (user?.signature.isNotEmpty == true)
                      ? null
                      : Colors.grey[400],
                  onTap: () => _editField(
                    context,
                    title: '修改签名',
                    initial: user?.signature ?? '',
                    maxLength: 100,
                    fieldName: 'signature',
                  ),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _group(List<Widget> rows) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Divider(height: 0.5, indent: 16, color: Colors.grey[200]),
          ],
        ],
      ),
    );
  }

  Widget _avatarRow(BuildContext context, String seed) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<SessionCubit>(),
              child: _AvatarEditPage(currentSeed: seed),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 72,
              child: Text('头像',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            IdenticonAvatar(seed: seed, size: 48, borderRadius: 6),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _row({
    required String label,
    String? value,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: value != null
                  ? Text(
                      value,
                      style: TextStyle(
                          fontSize: 16,
                          color: valueColor ?? Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    )
                  : const SizedBox.shrink(),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
            ],
          ],
        ),
      ),
    );
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.length < 5) return phone ?? '-';
    return '${phone.substring(0, 3)}${'*' * (phone.length - 5)}${phone.substring(phone.length - 2)}';
  }

  /// 跳转编辑页，完成后直接调接口保存
  void _editField(
    BuildContext context, {
    required String title,
    required String initial,
    required int maxLength,
    required String fieldName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<SessionCubit>(),
          child: _TextEditPage(
            title: title,
            initial: initial,
            maxLength: maxLength,
            fieldName: fieldName,
          ),
        ),
      ),
    );
  }
}

/// 文本编辑子页面 — 点完成直接调接口保存
class _TextEditPage extends StatefulWidget {
  final String title;
  final String initial;
  final int maxLength;
  final String fieldName; // 'nickname' or 'signature'

  const _TextEditPage({
    required this.title,
    required this.initial,
    required this.maxLength,
    required this.fieldName,
  });

  @override
  State<_TextEditPage> createState() => _TextEditPageState();
}

class _TextEditPageState extends State<_TextEditPage> {
  late TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text == widget.initial) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<SessionCubit>().updateProfile(
        nickname: widget.fieldName == 'nickname' ? text : null,
        signature: widget.fieldName == 'signature' ? text : null,
      );
      if (!mounted) return;
      showToast('保存成功');
      Navigator.of(context).pop();
    } catch (e) {
      showToast('保存失败: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(widget.title,
            style: const TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child:
              const Icon(Icons.arrow_back_ios, size: 18, color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('完成',
                    style:
                        TextStyle(color: Color(0xFF3B82F6), fontSize: 15)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLength: widget.maxLength,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterStyle: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}

/// 头像编辑页 — 预览 + 随机更换 + 保存
class _AvatarEditPage extends StatefulWidget {
  final String currentSeed;
  const _AvatarEditPage({required this.currentSeed});

  @override
  State<_AvatarEditPage> createState() => _AvatarEditPageState();
}

class _AvatarEditPageState extends State<_AvatarEditPage> {
  late String _seed;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _seed = widget.currentSeed;
  }

  void _randomize() {
    setState(() => _seed = Random().nextInt(999999).toString());
  }

  Future<void> _save() async {
    if (_seed == widget.currentSeed) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await context
          .read<SessionCubit>()
          .updateProfile(avatar: 'identicon:$_seed');
      if (!mounted) return;
      showToast('头像已更换');
      Navigator.of(context).pop();
    } catch (e) {
      showToast('保存失败: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text('修改头像',
            style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child:
              const Icon(Icons.arrow_back_ios, size: 18, color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('完成',
                    style:
                        TextStyle(color: Color(0xFF3B82F6), fontSize: 15)),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IdenticonAvatar(seed: _seed, size: 120, borderRadius: 12),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _randomize,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('随机更换', style: TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
