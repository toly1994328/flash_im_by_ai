import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

import '../../../data/auth_repository.dart';
import '../../../data/device_info.dart';
import '../../../data/login_result.dart';
import 'login_strategy.dart';

typedef SendEmailCodeCallback = Future<String?> Function(String email);

class EmailLoginStrategy extends LoginStrategy {
  final SendEmailCodeCallback sendEmailCodeCallback;
  final VoidCallback _refresh;

  final emailCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  int countdown = 0;
  bool _sending = false;
  Timer? _timer;

  EmailLoginStrategy({required this.sendEmailCodeCallback, required VoidCallback refresh})
      : _refresh = refresh;

  String get email => emailCtrl.text.trim();
  String get credential => codeCtrl.text.trim();

  bool get isEmailValid => email.contains('@') && email.contains('.');

  @override
  bool get isValid => isEmailValid && credential.isNotEmpty;

  bool get canSendCode => countdown <= 0 && !_sending;

  void listen() {
    emailCtrl.addListener(_refresh);
    codeCtrl.addListener(_refresh);
  }

  @override
  Future<LoginResult> login(AuthRepository repo, {DeviceInfo? deviceInfo}) {
    return repo.login(email, credential, 'email', deviceInfo: deviceInfo);
  }

  Future<void> sendCode() async {
    if (!isEmailValid) {
      showToast('请输入正确的邮箱地址');
      return;
    }
    if (_sending) return;
    _sending = true;
    _startCountdown();
    try {
      final code = await sendEmailCodeCallback(email);
      if (code != null) {
        codeCtrl.text = code;
      }
      showToast('验证码已发送');
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        showToast('发送过于频繁，请稍后再试');
      } else {
        showToast('发送失败，请检查网络');
      }
    } catch (e) {
      showToast('发送失败: $e');
    } finally {
      _sending = false;
    }
  }

  void _startCountdown() {
    countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown--;
      if (countdown <= 0) t.cancel();
      _refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    emailCtrl.dispose();
    codeCtrl.dispose();
  }
}
