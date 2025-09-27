import 'package:flutter_test/flutter_test.dart'
    hide test, group, setUp, tearDown, expect;
import 'package:test/test.dart';
import 'package:nx_di/src/types/disposal_types.dart';
import 'package:nx_di/src/exceptions/locator_exceptions.dart';

class TestService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('DependencyResolutionResult', () {
    test('success factory creates a successful result', () {
      final service = TestService();
      final result = DependencyResolutionResult.success(
        service,
        'test_profile',
        resolutionTimeUs: 10,
      );

      expect(result.instance, same(service));
      expect(result.sourceProfile, 'test_profile');
      expect(result.wasResolved, isTrue);
      expect(result.error, isNull);
      expect(result.resolutionTimeUs, 10);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('failure factory creates a failed result', () {
      final error = ObjectNotFoundException(
        'Type `TestService` is not registered in any active profile.',
        objectType: TestService,
      );
      final result = DependencyResolutionResult.failure(
        error,
        resolutionTimeUs: 5,
      );

      expect(result.instance, isNull);
      expect(result.sourceProfile, isNull);
      expect(result.wasResolved, isFalse);
      expect(result.error, same(error));
      expect(result.resolutionTimeUs, 5);
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
    });

    test('toString() returns correct string for success', () {
      final service = TestService();
      final result = DependencyResolutionResult.success(
        service,
        'test_profile',
        resolutionTimeUs: 15,
      );
      expect(
        result.toString(),
        'Success: TestService from test_profile (15μs)',
      );
    });

    test('toString() returns correct string for failure', () {
      final error = ObjectNotFoundException(
        'Type `TestService` is not registered in any active profile.',
        objectType: TestService,
      );
      final result = DependencyResolutionResult.failure(
        error,
        resolutionTimeUs: 8,
      );
      expect(
        result.toString(),
        startsWith(
          'Failure: ObjectNotFoundException: Could not find TestService. Type `TestService` is not registered in any active profile.',
        ),
      );
    });
  });

  group('DisposalInfo', () {
    test('constructor creates a successful disposal info', () {
      const info = DisposalInfo(
        objectType: TestService,
        instanceName: 'test_instance',
        profileName: 'test_profile',
        strategy: DisposalStrategy.onReset,
        wasSuccessful: true,
        disposalTimeUs: 20,
      );

      expect(info.objectType, TestService);
      expect(info.instanceName, 'test_instance');
      expect(info.profileName, 'test_profile');
      expect(info.strategy, DisposalStrategy.onReset);
      expect(info.wasSuccessful, isTrue);
      expect(info.error, isNull);
      expect(info.disposalTimeUs, 20);
    });

    test('constructor creates a failed disposal info', () {
      final error = Exception('Disposal failed');
      final info = DisposalInfo(
        objectType: TestService,
        profileName: 'test_profile',
        strategy: DisposalStrategy.onProfileDeactivation,
        wasSuccessful: false,
        error: error,
        disposalTimeUs: 25,
      );

      expect(info.objectType, TestService);
      expect(info.instanceName, isNull);
      expect(info.profileName, 'test_profile');
      expect(info.strategy, DisposalStrategy.onProfileDeactivation);
      expect(info.wasSuccessful, isFalse);
      expect(info.error, same(error));
      expect(info.disposalTimeUs, 25);
    });

    test('toString() returns correct string for successful disposal', () {
      const info = DisposalInfo(
        objectType: TestService,
        instanceName: 'test_instance',
        profileName: 'test_profile',
        strategy: DisposalStrategy.onUnregister,
        wasSuccessful: true,
        disposalTimeUs: 30,
      );
      expect(
        info.toString(),
        'Disposed: TestService("test_instance") from test_profile using DisposalStrategy.onUnregister (30μs)',
      );
    });

    test(
      'toString() returns correct string for successful disposal without instance name',
      () {
        const info = DisposalInfo(
          objectType: TestService,
          profileName: 'test_profile',
          strategy: DisposalStrategy.onUnregister,
          wasSuccessful: true,
          disposalTimeUs: 30,
        );
        expect(
          info.toString(),
          'Disposed: TestService from test_profile using DisposalStrategy.onUnregister (30μs)',
        );
      },
    );

    test('toString() returns correct string for failed disposal', () {
      final error = Exception('Disposal failed');
      final info = DisposalInfo(
        objectType: TestService,
        profileName: 'test_profile',
        strategy: DisposalStrategy.onAppShutdown,
        wasSuccessful: false,
        error: error,
        disposalTimeUs: 35,
      );
      expect(
        info.toString(),
        'Failed to dispose: TestService - Exception: Disposal failed (35μs)',
      );
    });
  });
}
