// src/core/nx_performance_optimizations.dart

import '../types/factory_types.dart';
import 'nx_locator.dart';

/// Ultra-fast lazy registration for maximum performance
class FastLazyRegistration<T extends Object> {
  final FactoryFunc<T> _factory;
  T? _instance;

  FastLazyRegistration(this._factory);

  T getInstance() {
    // Minimal lazy instantiation - no callbacks, no validation
    return _instance ??= _factory();
  }
}

/// Performance-optimized extensions for NxLocator
extension NxLocatorOptimizations on NxLocatorCallable {
  /// Ultra-fast lazy singleton registration with minimal overhead
  void registerFastLazySingleton<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
    String? profileName,
  }) {
    final profile = profileName != null
        ? locator.profiles.getProfile(profileName)
        : locator.getProfile('_default');

    if (profile == null) {
      throw Exception('Profile not found: $profileName');
    }

    profile.registerFastLazySingleton<T>(
      factoryFunc,
      instanceName: instanceName,
    );
  }

  /// Ultra-fast reset with minimal disposal overhead
  void resetFast({bool dispose = false}) {
    // Skip expensive async disposal and profile re-registration
    locator.profiles.clearAll(dispose: dispose);

    // Quick re-activation of default profile without full registration process
    locator.profiles.activateProfile('_default');
  }
}
