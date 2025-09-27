// test/test_helper.dart

import 'package:nx_di/nx_di.dart';
import 'package:test/test.dart';

export 'package:test/test.dart';

/// Simple test service A
class ServiceA {
  final String id = 'ServiceA';

  @override
  String toString() => 'ServiceA($id)';
}

/// Test service B that depends on ServiceA
class ServiceB {
  final ServiceA serviceA;

  ServiceB(this.serviceA);

  @override
  String toString() => 'ServiceB(serviceA: ${serviceA.id})';
}

/// Test service C for more complex scenarios
class ServiceC {
  final ServiceA serviceA;
  final ServiceB serviceB;

  ServiceC(this.serviceA, this.serviceB);

  @override
  String toString() =>
      'ServiceC(A: ${serviceA.id}, B: ${serviceB.serviceA.id})';
}

/// A service that implements disposal for testing
class DisposableService implements Disposable {
  bool _isDisposed = false;
  final String id = 'DisposableService';

  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      print('DisposableService($id) disposed');
    }
  }

  void doSomething() {
    if (_isDisposed) {
      throw StateError('Service has been disposed');
    }
    // Do some work
  }

  @override
  String toString() => 'DisposableService($id, disposed: $_isDisposed)';
}

/// Async disposable service for testing
class AsyncDisposableService implements AsyncDisposable {
  bool _isDisposed = false;
  final String id = 'AsyncDisposableService';

  bool get isDisposed => _isDisposed;

  @override
  Future<void> dispose() async {
    if (!_isDisposed) {
      _isDisposed = true;
      // Simulate async cleanup
      await Future.delayed(Duration(milliseconds: 10));
      print('AsyncDisposableService($id) disposed asynchronously');
    }
  }

  Future<void> doAsyncWork() async {
    if (_isDisposed) {
      throw StateError('Service has been disposed');
    }
    await Future.delayed(Duration(milliseconds: 5));
  }

  @override
  String toString() => 'AsyncDisposableService($id, disposed: $_isDisposed)';
}

/// Service for testing factory parameters
class ParameterizedService {
  final String config;
  final int value;

  ParameterizedService(this.config, this.value);

  @override
  String toString() => 'ParameterizedService(config: $config, value: $value)';
}

/// Service that requires specific initialization
class InitializableService {
  bool _initialized = false;
  String? _config;

  bool get isInitialized => _initialized;
  String? get config => _config;

  void initialize(String config) {
    if (_initialized) {
      throw StateError('Service already initialized');
    }
    _config = config;
    _initialized = true;
  }

  void doWork() {
    if (!_initialized) {
      throw StateError('Service not initialized');
    }
    // Do work with config
  }

  @override
  String toString() =>
      'InitializableService(initialized: $_initialized, config: $_config)';
}

/// Service for testing validation
class ValidatedService {
  final String name;
  final bool isValid;

  ValidatedService({required this.name, this.isValid = true});

  @override
  String toString() => 'ValidatedService(name: $name, valid: $isValid)';
}

/// Helper functions for tests

/// Create a basic test profile setup
void setupBasicProfiles(NxLocator locator) {
  locator.createProfile(name: 'base', priority: 0);
  locator.createProfile(name: 'test', priority: 10, dependsOn: ['base']);
}

/// Register common test services
void registerTestServices(NxLocator locator, {String? profileName}) {
  locator.registerSingleton<ServiceA>(ServiceA(), profileName: profileName);
  locator.registerFactory<ServiceB>(
    () => ServiceB(locator.get<ServiceA>()),
    profileName: profileName,
  );
  locator.registerLazySingleton<DisposableService>(
    () => DisposableService(),
    profileName: profileName,
  );
}

/// Create a locator with test setup
NxLocator createTestLocator() {
  final locator = NxLocator.asNewInstance();
  setupBasicProfiles(locator);
  registerTestServices(locator);
  return locator;
}

/// Assert that a service is properly registered and resolvable
void assertServiceResolvable<T extends Object>(NxLocator locator) {
  expect(
    locator.isRegistered<T>(),
    isTrue,
    reason: 'Service ${T} should be registered',
  );
  final instance = locator.get<T>();
  expect(
    instance,
    isA<T>(),
    reason: 'Retrieved instance should be of type ${T}',
  );
}

/// Assert that a service is not resolvable
void assertServiceNotResolvable<T extends Object>(NxLocator locator) {
  expect(
    locator.isRegistered<T>(),
    isFalse,
    reason: 'Service ${T} should not be registered',
  );
  expect(() => locator.get<T>(), throwsA(isA<ObjectNotFoundException>()));
}

// --- For Production Readiness Test ---

// For complex dependency graph test
class ComplexServiceC {}

class ComplexServiceB {
  final ComplexServiceC serviceC;
  ComplexServiceB(this.serviceC);
}

class ComplexServiceA {
  final ComplexServiceB serviceB;
  ComplexServiceA(this.serviceB);
}

class ComplexServiceD {
  final ComplexServiceB serviceB;
  ComplexServiceD(this.serviceB);
}

// For circular dependency test
class CircularA {
  final CircularB b;
  CircularA(this.b);
}

class CircularB {
  final CircularA a;
  CircularB(this.a);
}

// For overriding test
abstract class AbstractService {}

class ConcreteServiceA extends AbstractService {}

class ConcreteServiceB extends AbstractService {}
