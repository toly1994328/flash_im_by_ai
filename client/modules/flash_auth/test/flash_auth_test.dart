import 'package:flutter_test/flutter_test.dart';
import 'package:flash_auth/flash_auth.dart';

void main() {
  test('LoginResult.fromJson parses correctly', () {
    final json = {
      'token': 'abc123',
      'user_id': 42,
      'has_password': true,
    };
    final result = LoginResult.fromJson(json);
    expect(result.token, 'abc123');
    expect(result.userId, 42);
    expect(result.hasPassword, true);
  });
}
