import 'package:flutter_test/flutter_test.dart'
    hide test, group, setUp, tearDown, expect;
import 'package:nx_di/nx_di.dart';
import 'package:test/test.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late NxLocator nx;

  // Create a fresh, clean locator instance before each test
  setUp(() {
    nx = NxLocator.asNewInstance();
  });

  group('Profile Manager & Profiles Tests', () {
    test('services are only resolvable when their profile is active', () async {
      // 1. Setup
      nx.createProfile(name: 'test_profile');
      nx.registerSingleton<ServiceA>(ServiceA(), profileName: 'test_profile');

      // 2. Assert it's not available before activation
      expect(
        () => nx.get<ServiceA>(),
        throwsA(isA<ObjectNotFoundException>()),
        reason: 'Service should not be resolvable before profile is active.',
      );

      // 3. Activate and assert it's available
      await nx.activateProfile('test_profile');
      expect(nx.get<ServiceA>(), isA<ServiceA>());
      expect(nx.activeProfiles, contains('test_profile'));

      // 4. Deactivate and assert it's no longer available
      await nx.deactivateProfile('test_profile');
      expect(
        () => nx.get<ServiceA>(),
        throwsA(isA<ObjectNotFoundException>()),
        reason:
            'Service should not be resolvable after profile is deactivated.',
      );
      expect(nx.activeProfiles, isNot(contains('test_profile')));
    });

    test('resolution respects profile priority', () async {
      // 1. Setup two profiles with different priorities
      nx.createProfile(name: 'high_prio', priority: 100);
      nx.createProfile(name: 'low_prio', priority: 0);

      final highService = ServiceA();
      final lowService = ServiceA();

      // 2. Register the same type in both profiles
      nx.registerSingleton<ServiceA>(highService, profileName: 'high_prio');
      nx.registerSingleton<ServiceA>(lowService, profileName: 'low_prio');

      // 3. Activate both, ensuring order doesn't matter
      await nx.activateProfile('low_prio');
      await nx.activateProfile('high_prio');

      // 4. Assert that the service from the higher priority profile is returned
      final resolvedService = nx.get<ServiceA>();
      expect(resolvedService, same(highService));
      expect(resolvedService, isNot(same(lowService)));
    });

    test(
      'activating a profile also activates its dependencies (`dependsOn`)',
      () async {
        // 1. Setup a dependency chain: B depends on A
        nx.createProfile(name: 'profileA');
        nx.createProfile(name: 'profileB', dependsOn: ['profileA']);

        // FIXED: Register services with factory functions instead of immediate resolution
        // This way ServiceA doesn't need to be resolved during registration
        nx.registerSingleton<ServiceA>(ServiceA(), profileName: 'profileA');
        nx.registerFactory<ServiceB>(
          () => ServiceB(
            nx.get<ServiceA>(),
          ), // This will resolve ServiceA when ServiceB is requested
          profileName: 'profileB',
        );

        // 2. Activate only the dependent profile
        await nx.activateProfile('profileB');

        // 3. Assert both profiles are now active
        expect(nx.activeProfiles, containsAll(['profileA', 'profileB']));

        // 4. Assert services from both profiles are resolvable
        expect(nx.get<ServiceA>(), isA<ServiceA>());
        expect(nx.get<ServiceB>(), isA<ServiceB>());
      },
    );

    test('deactivating a required dependency throws a ProfileException', () async {
      // 1. Setup a dependency chain
      nx.createProfile(name: 'profileA');
      nx.createProfile(name: 'profileB', dependsOn: ['profileA']);
      await nx.activateProfile('profileB'); // This also activates 'profileA'

      // 2. Assert that deactivating 'profileA' fails because 'profileB' needs it
      expect(
        () => nx.deactivateProfile('profileA'),
        throwsA(isA<ProfileException>()),
        reason:
            'Should not be able to deactivate a profile that is a dependency of another active profile.',
      );
    });

    test(
      'activating a profile with a circular dependency throws a CircularDependencyException',
      () async {
        // 1. Setup a circular dependency: A -> B -> A
        nx.createProfile(name: 'profileA', dependsOn: ['profileB']);
        nx.createProfile(name: 'profileB', dependsOn: ['profileA']);

        // 2. Assert that activation throws the correct exception
        expect(
          () => nx.activateProfile('profileA'),
          throwsA(isA<CircularDependencyException>()),
        );
      },
    );

    test(
      'deactivating a profile with dispose=true disposes its services',
      () async {
        final disposableService = DisposableService();
        nx.createProfile(name: 'disposable_profile');
        nx.registerSingleton<DisposableService>(
          disposableService,
          profileName: 'disposable_profile',
        );
        await nx.activateProfile('disposable_profile');

        // Deactivate and dispose
        await nx.deactivateProfile('disposable_profile', dispose: true);

        expect(disposableService.isDisposed, isTrue);
      },
    );

    test(
      'deactivating a profile with dispose=false does NOT dispose its services',
      () async {
        final disposableService = DisposableService();
        nx.createProfile(name: 'disposable_profile');
        nx.registerSingleton<DisposableService>(
          disposableService,
          profileName: 'disposable_profile',
        );
        await nx.activateProfile('disposable_profile');

        // Deactivate but do NOT dispose
        await nx.deactivateProfile('disposable_profile', dispose: false);

        expect(disposableService.isDisposed, isFalse);
      },
    );
  });
}
