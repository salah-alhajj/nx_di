import 'package:nx_di/nx_di.dart';
import '../test_helper.dart';

void main() {
  // Use a local instance for better test isolation
  late NxLocator nx;

  setUp(() async {
    // Create a fresh locator for each test
    nx = NxLocator.asNewInstance();
  });

  group('NxLocator Core API Tests', () {
    test('instance returns the same object', () {
      // The global instance should be a singleton
      expect(NxLocator.instance, same(NxLocator.instance));
    });

    test('asNewInstance returns a new object', () {
      final newInstance = NxLocator.asNewInstance();
      // A new instance should not be the same as the global one
      expect(newInstance, isNot(same(NxLocator.instance)));
    });

    test('registerFactory creates new instances on each get', () {
      nx.registerFactory<ServiceA>(() => ServiceA());

      final instance1 = nx.get<ServiceA>();
      final instance2 = nx.get<ServiceA>();

      expect(instance1, isA<ServiceA>());
      expect(instance2, isA<ServiceA>());
      expect(
        instance1,
        isNot(same(instance2)),
        reason: 'Factories should produce new instances.',
      );
    });

    test('registerLazySingleton creates only one instance', () {
      int factoryCallCount = 0;
      nx.registerLazySingleton<ServiceA>(() {
        factoryCallCount++;
        return ServiceA();
      });

      final instance1 = nx.get<ServiceA>();
      final instance2 = nx.get<ServiceA>();

      expect(
        factoryCallCount,
        1,
        reason: 'Lazy Singleton factory should be called only once.',
      );
      expect(
        instance1,
        same(instance2),
        reason: 'Subsequent gets should return the same instance.',
      );
    });

    test('registerSingleton returns the provided instance', () {
      final preMadeInstance = ServiceA();
      nx.registerSingleton<ServiceA>(preMadeInstance);

      final retrievedInstance = nx.get<ServiceA>();

      expect(retrievedInstance, same(preMadeInstance));
    });

    test('registerFactoryParam correctly passes parameters', () {
      final dependency = ServiceA();
      nx.registerFactoryParam<ServiceB, ServiceA>(
        (serviceA) => ServiceB(serviceA),
      );

      final instance = nx.get<ServiceB>(param1: dependency);

      expect(instance, isA<ServiceB>());
      expect(instance.serviceA, same(dependency));
    });

    test('get throws ObjectNotFoundException for unregistered type', () {
      expect(() => nx.get<ServiceA>(), throwsA(isA<ObjectNotFoundException>()));
    });

    test('tryGet returns null for unregistered type', () {
      expect(nx.tryGet<ServiceA>(), isNull);
    });

    test('tryGet returns an instance for a registered type', () {
      nx.registerSingleton(ServiceA());
      expect(nx.tryGet<ServiceA>(), isA<ServiceA>());
    });

    test('isRegistered works correctly', () {
      expect(nx.isRegistered<ServiceA>(), isFalse);
      nx.registerSingleton(ServiceA());
      expect(nx.isRegistered<ServiceA>(), isTrue);
    });

    test(
      'unregister removes a registration and makes it unresolvable',
      () async {
        nx.registerSingleton(ServiceA());
        expect(nx.isRegistered<ServiceA>(), isTrue);

        final unregistered = await nx.unregister<ServiceA>();
        expect(unregistered, isTrue);
        expect(nx.isRegistered<ServiceA>(), isFalse);
        expect(
          () => nx.get<ServiceA>(),
          throwsA(isA<ObjectNotFoundException>()),
        );
      },
    );
  });
}
