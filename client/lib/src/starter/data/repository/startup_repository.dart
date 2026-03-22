import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/model/user.dart';
import '../model/startup_result.dart';

class StartupRepository {
  final _controller = StreamController<StartupEvent>.broadcast();

  Stream<StartupEvent> get stream => _controller.stream;

  Future<void> initialize() async {
    _controller.add(StartupLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        _controller.add(StartupReady(const StartupResult()));
        return;
      }
      final userJson = prefs.getString('user_info');
      final user = userJson != null
          ? User.fromJson(jsonDecode(userJson) as Map<String, dynamic>)
          : null;
      final hasPassword = prefs.getBool('has_password') ?? false;

      _controller.add(StartupReady(StartupResult(
        token: token,
        user: user,
        hasPassword: hasPassword,
      )));
    } catch (e) {
      _controller.add(StartupFailed(e.toString()));
    }
  }

  void dispose() => _controller.close();
}
