import 'package:flutter_test/flutter_test.dart'
    hide test, group, setUp, tearDown, expect;
import 'package:nx_di/nx_di.dart';
import '../test_helper.dart';
import 'package:test/test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Migration Tests', () {
    late NxLocator nx;

    setUp(() {
      nx = NxLocator.asNewInstance();
    });

    test('basic get_it compatibility - registerFactory', () {
      // Test that the API is compatible with get_it
      nx.registerFactory<ServiceA>(() => ServiceA());

      expect(nx.isRegistered<ServiceA>(), isTrue);

      final service1 = nx.get<ServiceA>();
      final service2 = nx.get<ServiceA>();

      expect(service1, isA<ServiceA>());
      expect(service2, isA<ServiceA>());
      expect(service1, isNot(same(service2)));
    });

    test('basic get_it compatibility - registerSingleton', () {
      final serviceInstance = ServiceA();
      nx.registerSingleton<ServiceA>(serviceInstance);

      expect(nx.isRegistered<ServiceA>(), isTrue);

      final retrieved = nx.get<ServiceA>();
      expect(retrieved, same(serviceInstance));
    });

    test('basic get_it compatibility - registerLazySingleton', () {
      nx.registerLazySingleton<ServiceA>(() => ServiceA());

      expect(nx.isRegistered<ServiceA>(), isTrue);

      final service1 = nx.get<ServiceA>();
      final service2 = nx.get<ServiceA>();

      expect(service1, isA<ServiceA>());
      expect(service1, same(service2)); // Same instance
    });

    test('unregister functionality', () {
      nx.registerFactory<ServiceA>(() => ServiceA());
      expect(nx.isRegistered<ServiceA>(), isTrue);

      nx.unregister<ServiceA>();
      expect(nx.isRegistered<ServiceA>(), isFalse);
    });

    test('reset functionality', () async {
      nx.registerFactory<ServiceA>(() => ServiceA());
      nx.registerSingleton<ServiceB>(ServiceB(ServiceA()));

      expect(nx.isRegistered<ServiceA>(), isTrue);
      expect(nx.isRegistered<ServiceB>(), isTrue);

      await nx.reset();

      expect(nx.isRegistered<ServiceA>(), isFalse);
      expect(nx.isRegistered<ServiceB>(), isFalse);
    });
  });
}
