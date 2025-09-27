import 'package:test/test.dart';
import 'package:nx_di/src/core/nx_locator.dart';

// Minimal test case to isolate the segfault issue
class SimpleService {
  String getValue() => 'test';
}

void main() {
  group('Minimal Test', () {
    tearDown(() async {
      await NxLocator.instance.reset();
    });

    test('simple registration and retrieval', () {
      NxLocator.instance.registerSingleton<SimpleService>(SimpleService());
      final service = NxLocator.instance.get<SimpleService>();
      expect(service.getValue(), equals('test'));
    });

    test('another simple test', () {
      NxLocator.instance.registerFactory<SimpleService>(() => SimpleService());
      final service = NxLocator.instance<SimpleService>();
      expect(service.getValue(), equals('test'));
    });
  });
}
