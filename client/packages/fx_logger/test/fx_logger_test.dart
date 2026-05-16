import 'package:flutter_test/flutter_test.dart';
import 'package:fx_logger/fx_logger.dart';

void main() {
  test('FxLog instance can be created with tag', () {
    final log = FxLog('TestTag');
    expect(log.tag, 'TestTag');
  });

  test('Same tag returns same instance', () {
    final log1 = FxLog('Same');
    final log2 = FxLog('Same');
    expect(identical(log1, log2), true);
  });

  test('LogLevel ordering', () {
    expect(LogLevel.debug.index < LogLevel.error.index, true);
    expect(LogLevel.warning.index < LogLevel.error.index, true);
  });
}
