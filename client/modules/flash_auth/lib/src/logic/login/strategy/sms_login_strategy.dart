import 'dart:async';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

import '../../../data/auth_repository.dart';
import '../../../data/login_result.dart';
import 'login_strategy.dart';

typedef SendSmsCallback = Future<String> Function(String phone);

class SmsLoginStrategy extends LoginStrategy {
  final SendSmsCallback sendSmsCallback;
  final VoidCallback _refresh;

  final phoneCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  int countdown = 0;
  Timer? _timer;

  SmsLoginStrategy({required this.sendSmsCallback, required VoidCallback refresh})
      : _refresh = refresh;

  String get phone => phoneCtrl.text.trim();
  String get credential => codeCtrl.text.trim();

  bool get isPhoneValid => phone.length == 11 && phone.startsWith('1');

  @override
  bool get isValid => isPhoneValid && credential.isNotEmpty;

  bool get canSendSms => countdown <= 0;

  void listen() {
    phoneCtrl.addListener(_refresh);
    codeCtrl.addListener(_refresh);
  }

  @override
  Future<LoginResult> login(AuthRepository repo) {
    return repo.login(phone, credential, 'sms');
  }

  Future<void> sendSms() async {
    if (!isPhoneValid) {
      showToast('请输入正确的手机号');
      return;
    }
    try {
      final code = await sendSmsCallback(phone);
      codeCtrl.text = code;
      _startCountdown();
    } catch (e) {
      showToast('发送失败: $e');
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
    phoneCtrl.dispose();
    codeCtrl.dispose();
  }
}
