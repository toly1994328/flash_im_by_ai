import 'package:flutter_test/flutter_test.dart';
import 'package:flash_shared/flash_shared.dart';

void main() {
  test('AvatarWidget can be instantiated', () {
    const widget = AvatarWidget(avatar: 'identicon:test');
    expect(widget.avatar, 'identicon:test');
  });
}
