import 'package:test/test.dart';
import 'package:nx_di/nx_di.dart';

class AsyncService {
  final String data;
  AsyncService(this.data);
}

Future<AsyncService> createAsyncService() async {
  await Future.delayed(const Duration(milliseconds: 100));
  return AsyncService('Async data');
}

void main() {
  group('Async Tests', () {
    tearDown(() async {
      await NxLocator.instance.reset();
    });

    test('registerSingletonAsync and getAsync work correctly', () async {
      NxLocator.instance.registerSingletonAsync<AsyncService>(
        createAsyncService,
      );

      final service = await NxLocator.instance.getAsync<AsyncService>();

      expect(service, isA<AsyncService>());
      expect(service.data, 'Async data');
    });

    test('get throws error for async singleton', () {
      NxLocator.instance.registerSingletonAsync<AsyncService>(
        createAsyncService,
      );

      expect(
        () => NxLocator.instance.get<AsyncService>(),
        throwsA(isA<ObjectNotFoundException>()),
      );
    });
  });
}
