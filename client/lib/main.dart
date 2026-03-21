import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/auth/service/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  runApp(FlashApp(authService: authService));
}
