import 'package:flutter/material.dart';

import '../../../data/auth_repository.dart';
import '../../../data/login_result.dart';
import 'login_strategy.dart';

class PasswordLoginStrategy extends LoginStrategy {
  final VoidCallback _refresh;

  final accountCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  PasswordLoginStrategy({required VoidCallback refresh}) : _refresh = refresh;

  String get phone => accountCtrl.text.trim();
  String get credential => passwordCtrl.text.trim();

  @override
  bool get isValid => phone.isNotEmpty && credential.isNotEmpty;

  void listen() {
    accountCtrl.addListener(_refresh);
    passwordCtrl.addListener(_refresh);
  }

  @override
  Future<LoginResult> login(AuthRepository repo) {
    return repo.login(phone, credential, 'password');
  }

  @override
  void dispose() {
    accountCtrl.dispose();
    passwordCtrl.dispose();
  }
}
