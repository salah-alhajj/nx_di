import 'dart:async';
import 'package:test/test.dart';
import 'package:nx_di/nx_di.dart';
import '../test_helper.dart';

void main() {
  late NxLocator nx;

  setUp(() {
    // Create a fresh locator for each test for isolation
    nx = NxLocator.asNewInstance();
  });

  group('Production Readiness Tests -', () {
    group('Core Functionality -', () {
      test('should handle complex dependency graph for singletons', () {
        // A -> B -> C
        // D -> B
        nx.registerSingleton(ComplexServiceC());
        nx.registerSingleton(ComplexServiceB(nx.get<ComplexServiceC>()));
        nx.registerSingleton(ComplexServiceA(nx.get<ComplexServiceB>()));
        nx.registerSingleton(ComplexServiceD(nx.get<ComplexServiceB>()));

        final serviceA = nx.get<ComplexServiceA>();
        final serviceD = nx.get<ComplexServiceD>();

        expect(serviceA, isA<ComplexServiceA>());
        expect(serviceD, isA<ComplexServiceD>());
        expect(serviceA.serviceB, isA<ComplexServiceB>());
        expect(serviceD.serviceB, isA<ComplexServiceB>());
        expect(
          serviceA.serviceB,
          same(serviceD.serviceB),
        ); // Should be the same instance
        expect(serviceA.serviceB.serviceC, isA<ComplexServiceC>());
      });

      test('should differentiate between named and unnamed instances', () {
        nx.registerSingleton(ServiceA());
        nx.registerSingleton(ServiceA(), instanceName: 'named');

        final instance1 = nx.get<ServiceA>();
        final instance2 = nx.get<ServiceA>(instanceName: 'named');

        expect(instance1, isNot(same(instance2)));
      });

      test(
        'lazy singletons should be initialized only once on first access',
        () {
          int initCounter = 0;
          nx.registerLazySingleton(() {
            initCounter++;
            return ServiceA();
          });

          expect(initCounter, 0);

          final instance1 = nx.get<ServiceA>();
          expect(initCounter, 1);

          final instance2 = nx.get<ServiceA>();
          expect(initCounter, 1); // Should not increment again

          expect(instance1, same(instance2));
        },
      );

      test('factories should create new instances on every access', () {
        nx.registerFactory(() => ServiceA());

        final instance1 = nx.get<ServiceA>();
        final instance2 = nx.get<ServiceA>();

        expect(instance1, isNot(same(instance2)));
      });

      test('should allow overriding registrations when specified', () {
        nx.registerSingleton<AbstractService>(ConcreteServiceA());
        final instance1 = nx.get<AbstractService>();
        expect(instance1, isA<ConcreteServiceA>());

        // Re-registering with a new type should override the previous one.
        nx.registerSingleton<AbstractService>(
          ConcreteServiceB(),
          options: RegistrationOptions(allowOverride: true),
        );
        final instance2 = nx.get<AbstractService>();
        expect(instance2, isA<ConcreteServiceB>());
        expect(instance1, isNot(same(instance2)));
      });
    });

    group('Async Operations -', () {
      test('should handle async singleton registrations', () async {
        int initCounter = 0;
        nx.registerSingletonAsync<ServiceA>(() async {
          initCounter++;
          await Future.delayed(Duration(milliseconds: 20));
          return ServiceA();
        });

        // Accessing it before it's ready should wait
        final instance1 = await nx.getAsync<ServiceA>();
        expect(initCounter, 1);
        expect(instance1, isA<ServiceA>());

        // Accessing it again should return the same instance without re-initializing
        final instance2 = await nx.getAsync<ServiceA>();
        expect(initCounter, 1); // Should not init again
        expect(instance1, same(instance2));
      });
    });

    group('Disposal Logic -', () {
      test('reset should dispose all registered singletons', () async {
        final disposable = DisposableService();
        nx.registerSingleton<DisposableService>(disposable);

        expect(disposable.isDisposed, isFalse);
        await nx.reset();
        expect(disposable.isDisposed, isTrue);
      });

      test('unregister should dispose the specific singleton', () async {
        final disposable1 = DisposableService();
        final disposable2 = DisposableService();
        nx.registerSingleton<DisposableService>(
          disposable1,
          instanceName: 'd1',
        );
        nx.registerSingleton<DisposableService>(
          disposable2,
          instanceName: 'd2',
        );

        expect(disposable1.isDisposed, isFalse);
        expect(disposable2.isDisposed, isFalse);

        await nx.unregister<DisposableService>(instanceName: 'd1');

        expect(disposable1.isDisposed, isTrue);
        expect(disposable2.isDisposed, isFalse);
        expect(
          () => nx.get<DisposableService>(instanceName: 'd1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Profiles -', () {
      test('should override services from a less specific profile', () async {
        // 1. Register a service in the default profile
        nx.registerSingleton<AbstractService>(ConcreteServiceA());

        // 2. Create and activate a new profile
        nx.createProfile(name: 'test_profile');
        await nx.activateProfile('test_profile');

        // 3. Register a different implementation in the new profile
        nx.registerSingleton<AbstractService>(
          ConcreteServiceB(),
          profileName: 'test_profile',
          options: RegistrationOptions(
            allowOverride: true,
          ), // Allow overriding the base one
        );

        // 4. Assert that get<AbstractService>() now returns the implementation from the active profile
        expect(nx.get<AbstractService>(), isA<ConcreteServiceB>());

        // 5. Deactivate the profile
        await nx.deactivateProfile('test_profile');

        // 6. Assert that get<AbstractService>() now returns the implementation from the default profile
        expect(nx.get<AbstractService>(), isA<ConcreteServiceA>());
      });
    });

    group('Error Handling & Edge Cases -', () {
      test('should throw when resolving an unregistered service', () {
        expect(() => nx.get<ServiceA>(), throwsA(isA<Exception>()));
      });

      test('should throw on circular dependencies', () {
        nx.registerFactory<CircularA>(() => CircularA(nx.get<CircularB>()));
        nx.registerFactory<CircularB>(() => CircularB(nx.get<CircularA>()));

        expect(() => nx.get<CircularA>(), throwsA(isA<Exception>()));
      });
    });

    group('Stress Test -', () {
      test(
        'should handle a large number of registrations and lookups efficiently',
        () {
          final count = 10000;
          for (int i = 0; i < count; i++) {
            nx.registerFactory<ServiceA>(
              () => ServiceA(),
              instanceName: 'service_$i',
            );
          }

          final stopwatch = Stopwatch()..start();
          for (int i = 0; i < count; i++) {
            final instance = nx.get<ServiceA>(instanceName: 'service_$i');
            expect(instance, isA<ServiceA>());
          }
          stopwatch.stop();
          print(
            'Stress test with $count factories took ${stopwatch.elapsedMilliseconds}ms',
          );
          // This is not a hard assertion, but a check to ensure it's reasonably fast.
          // A typical run on a modern machine should be well under 500ms.
          expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        },
      );
    });
  });
}
