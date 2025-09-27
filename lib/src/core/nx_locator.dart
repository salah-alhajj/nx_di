// src/core/nx_locator.dart

import 'dart:async';
import 'package:nx_di/src/core/registration_options.dart';
import 'package:nx_di/src/profiles/profile.dart';
import 'package:nx_di/src/profiles/profile_manager.dart';
import 'package:nx_di/src/types/factory_types.dart';
import 'package:nx_di/src/exceptions/locator_exceptions.dart';

/// The main NxLocator class - Next Generation Dependency Injection
///
/// Drop-in replacement for get_it with enhanced multi-profile support
class NxLocator {
  static NxLocator? _instance;
  static NxLocatorCallable? _instanceCallable;

  final ProfileManager _profileManager = ProfileManager();
  final Profile _defaultProfile = Profile(name: '_default', priority: -1000);

  NxLocator._internal() {
    // Register the default profile
    _profileManager.registerProfile(_defaultProfile);

    // FIXED: Use the internal sync method to activate default profile
    _profileManager.activateDefaultProfileSync('_default');
  }

  /// Get the singleton instance
  static NxLocator _getInstance() {
    return _instance ??= NxLocator._internal();
  }

  static NxLocatorCallable get instance {
    return _instanceCallable ??= NxLocatorCallable._(_getInstance());
  }

  /// Create a new NxLocator instance
  static NxLocator asNewInstance() {
    return NxLocator._internal();
  }

  /// The name of this locator instance (useful for debugging)
  String get instanceName => 'default';

  /// Profile manager for advanced profile operations
  ProfileManager get profiles => _profileManager;

  /// Currently active profile names
  Set<String> get activeProfiles => _profileManager.activeProfiles;

  // ===== REGISTRATION METHODS (get_it compatible) =====

  /// Register a factory function that will be called each time [get] is called
  ///
  /// Example:
  /// ```dart
  /// nx.registerFactory<ApiService>(() => ApiService());
  /// ```
  void registerFactory<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
    String? profileName,
    RegistrationOptions<T>? options,
  }) {
    final profile = _getTargetProfile(profileName);
    profile.registerFactory<T>(
      factoryFunc,
      instanceName: instanceName,
      options: options,
    );
  }

  /// Register a factory function that will be called only once
  /// Returns the same instance for every call to [get]
  ///
  /// Example:
  /// ```dart
  /// nx.registerLazySingleton<ApiService>(() => ApiService());
  /// ```
  void registerLazySingleton<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
    String? profileName,
    RegistrationOptions<T>? options,
  }) {
    final profile = _getTargetProfile(profileName);
    profile.registerLazySingleton<T>(
      factoryFunc,
      instanceName: instanceName,
      options: options,
    );
  }

  /// Register an existing instance as singleton
  ///
  /// Example:
  /// ```dart
  /// final apiService = ApiService();
  /// nx.registerSingleton<ApiService>(apiService);
  /// ```
  void registerSingleton<T extends Object>(
    T instance, {
    String? instanceName,
    String? profileName,
    RegistrationOptions<T>? options,
    bool? signalReady,
  }) {
    final profile = _getTargetProfile(profileName);

    // Handle legacy signalReady parameter
    RegistrationOptions<T> effectiveOptions =
        options ?? RegistrationOptions<T>();
    if (signalReady == true && options?.signalReady != true) {
      effectiveOptions = effectiveOptions.copyWith(signalReady: true);
    }

    profile.registerSingleton<T>(
      instance,
      instanceName: instanceName,
      options: effectiveOptions,
    );
  }

  /// Register an async factory function as a singleton
  void registerSingletonAsync<T extends Object>(
    FactoryFuncAsync<T> factoryFunc, {
    String? instanceName,
    String? profileName,
    RegistrationOptions<T>? options,
  }) {
    final profile = _getTargetProfile(profileName);
    profile.registerSingletonAsync<T>(
      factoryFunc,
      instanceName: instanceName,
      options: options,
    );
  }

  /// Register a factory function with one parameter
  ///
  /// Example:
  /// ```dart
  /// nx.registerFactoryParam<UserService, String>((userId) => UserService(userId));
  /// final userService = nx.get<UserService>(param1: 'user123');
  /// ```
  void registerFactoryParam<T extends Object, P1>(
    FactoryFuncParam<T, P1> factoryFunc, {
    String? instanceName,
    String? profileName,
    RegistrationOptions<T>? options,
  }) {
    final profile = _getTargetProfile(profileName);
    profile.registerFactoryParam<T, P1>(
      factoryFunc,
      instanceName: instanceName,
      options: options,
    );
  }

  /// Register a factory function with two parameters
  ///
  /// Example:
  /// ```dart
  /// nx.registerFactoryParam2<DatabaseService, String, int>((host, port) => DatabaseService(host, port));
  /// final dbService = nx.get<DatabaseService>(param1: 'localhost', param2: 5432);
  /// ```
  void registerFactoryParam2<T extends Object, P1, P2>(
    FactoryFuncParam2<T, P1, P2> factoryFunc, {
    String? instanceName,
    String? profileName,
    RegistrationOptions<T>? options,
  }) {
    final profile = _getTargetProfile(profileName);
    profile.registerFactoryParam2<T, P1, P2>(
      factoryFunc,
      instanceName: instanceName,
      options: options,
    );
  }

  // ===== RESOLUTION METHODS (get_it compatible) =====

  /// Get an instance of type [T] from active profiles
  ///
  /// Example:
  /// ```dart
  /// final apiService = nx.get<ApiService>();
  /// final namedService = nx.get<ApiService>(instanceName: 'special');
  /// ```
  T get<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) {
    return _profileManager.resolve<T>(
      instanceName: instanceName,
      param1: param1,
      param2: param2,
    );
  }

  /// Try to get an instance of type [T], returns null if not found
  ///
  /// Example:
  /// ```dart
  /// final apiService = nx.tryGet<ApiService>();
  /// if (apiService != null) {
  ///   // Use the service
  /// }
  /// ```
  T? tryGet<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) {
    return _profileManager.tryResolve<T>(
      instanceName: instanceName,
      param1: param1,
      param2: param2,
    );
  }

  /// Get an instance with async initialization
  ///
  /// Example:
  /// ```dart
  /// final apiService = await nx.getAsync<ApiService>();
  /// ```
  Future<T> getAsync<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) async {
    return _profileManager.resolveAsync<T>(
      instanceName: instanceName,
      param1: param1,
      param2: param2,
    );
  }

  // ===== QUERY METHODS (get_it compatible) =====

  /// Check if type [T] is registered in active profiles
  ///
  /// Example:
  /// ```dart
  /// if (nx.isRegistered<ApiService>()) {
  ///   final service = nx.get<ApiService>();
  /// }
  /// ```
  bool isRegistered<T extends Object>({
    String? instanceName,
    String? profileName,
  }) {
    if (profileName != null) {
      final profile = _profileManager.getProfile(profileName);
      return profile?.isRegistered<T>(instanceName: instanceName) ?? false;
    }
    return _profileManager.isRegistered<T>(instanceName: instanceName);
  }

  /// Get all registered types across all profiles
  Iterable<Type> get registeredTypes {
    final types = <Type>{};
    for (final profile in _profileManager.profiles.values) {
      types.addAll(profile.registeredTypes);
    }
    return types;
  }

  // ===== PROFILE MANAGEMENT (nx_di exclusive) =====

  /// Create and register a new profile
  ///
  /// Example:
  /// ```dart
  /// final userProfile = nx.createProfile(
  ///   name: 'user',
  ///   priority: 100,
  ///   dependsOn: ['base'],
  /// );
  /// ```
  Profile createProfile({
    required String name,
    String? description,
    int priority = 0,
    List<String> dependsOn = const [],
  }) {
    final profile = Profile(
      name: name,
      description: description,
      priority: priority,
      dependsOn: dependsOn,
    );

    _profileManager.registerProfile(profile);
    return profile;
  }

  /// Activate a profile
  ///
  /// Example:
  /// ```dart
  /// await nx.activateProfile('user');
  /// ```
  Future<void> activateProfile(String profileName) async {
    await _profileManager.activateProfile(profileName);
  }

  /// Deactivate a profile
  ///
  /// Example:
  /// ```dart
  /// await nx.deactivateProfile('debug');
  /// ```
  Future<void> deactivateProfile(
    String profileName, {
    bool dispose = true,
  }) async {
    await _profileManager.deactivateProfile(profileName, dispose: dispose);
  }

  /// Switch to specific profiles, deactivating others
  ///
  /// Example:
  /// ```dart
  /// await nx.switchToProfiles({'base', 'user', 'mobile'});
  /// ```
  Future<void> switchToProfiles(Set<String> profileNames) async {
    await _profileManager.switchToProfiles(profileNames);
  }

  /// Get a specific profile by name
  ///
  /// Example:
  /// ```dart
  /// final userProfile = nx.getProfile('user');
  /// if (userProfile != null) {
  ///   // Use profile directly
  /// }
  /// ```
  Profile? getProfile(String name) {
    return _profileManager.getProfile(name);
  }

  // ===== CLEANUP METHODS (get_it compatible) =====

  /// Unregister a specific type
  ///
  /// Example:
  /// ```dart
  /// final wasRemoved = await nx.unregister<ApiService>();
  /// ```
  Future<bool> unregister<T extends Object>({
    String? instanceName,
    String? profileName,
    bool disposeDependency = true,
  }) async {
    if (profileName != null) {
      final profile = _profileManager.getProfile(profileName);
      return profile?.unregister<T>(
            instanceName: instanceName,
            disposeDependency: disposeDependency,
          ) ??
          false;
    }

    // Unregister from all profiles
    bool wasRemoved = false;
    for (final profile in _profileManager.profiles.values) {
      if (profile.unregister<T>(
        instanceName: instanceName,
        disposeDependency: disposeDependency,
      )) {
        wasRemoved = true;
      }
    }
    return wasRemoved;
  }

  /// Reset the entire locator
  ///
  /// Example:
  /// ```dart
  /// await nx.reset();
  /// ```
  Future<void> reset({bool dispose = true}) async {
    // Choose fastest reset path based on disposal needs
    if (dispose) {
      // Fast async reset with optimized disposal
      await resetFast(dispose: true);
    } else {
      // Ultra-fast synchronous reset without disposal
      resetSync();
    }
  }

  /// Ultra-fast reset with optimized disposal
  Future<void> resetFast({bool dispose = true}) async {
    // Clear all profiles and the default profile
    await _profileManager.clearAll(dispose: dispose);
    await _defaultProfile.clear(dispose: dispose);

    // Re-register and reactivate default profile
    _profileManager.registerProfile(_defaultProfile);
    _profileManager.activateDefaultProfileSync('_default');
  }

  /// Ultra-fast synchronous reset (no disposal)
  void resetSync() {
    // Synchronous cleanup for maximum speed - clear without disposal
    _defaultProfile.clearFast();

    // Clear profiles without disposal
    _profileManager.profiles.clear();
    _profileManager.activeProfiles.clear();

    // Re-register and reactivate default profile
    _profileManager.registerProfile(_defaultProfile);
    _profileManager.activateDefaultProfileSync('_default');
  }
}

extension NxLocatorFeatures on NxLocator {
  // ===== ADVANCED FEATURES (nx_di exclusive) =====

  /// Get comprehensive performance statistics
  ///
  /// Example:
  /// ```dart
  /// final stats = nx.getPerformanceStats();
  /// print('Total services: ${stats['total_services']}');
  /// ```
  Map<String, dynamic> getPerformanceStats() {
    return _profileManager.getPerformanceStats();
  }

  /// Validate all active profiles and their dependencies
  ///
  /// Example:
  /// ```dart
  /// final issues = await nx.validateProfiles();
  /// if (issues.isNotEmpty) {
  ///   for (final issue in issues) {
  ///     print('Validation issue: ${issue.message}');
  ///   }
  /// }
  /// ```
  Future<List<ValidationIssue>> validateProfiles() async {
    return await _profileManager.validateProfiles();
  }

  /// Add a profile change listener
  ///
  /// Example:
  /// ```dart
  /// nx.addProfileChangeListener((profileName, changeType) {
  ///   print('Profile $profileName changed: $changeType');
  /// });
  /// ```
  void addProfileChangeListener(ProfileChangeCallback listener) {
    _profileManager.addChangeListener(listener);
  }

  /// Remove a profile change listener
  bool removeProfileChangeListener(ProfileChangeCallback listener) {
    return _profileManager.removeChangeListener(listener);
  }

  // Internal helper methods

  Profile _getTargetProfile(String? profileName) {
    if (profileName == null) {
      return _defaultProfile;
    }

    final profile = _profileManager.getProfile(profileName);
    if (profile == null) {
      throw ProfileException(
        'Profile "$profileName" is not registered',
        profileName: profileName,
      );
    }

    return profile;
  }

  String toDetailString() =>
      'NxLocator(instanceName: $instanceName, profiles: ${_profileManager.profiles.length}, active: ${_profileManager.activeProfiles.length})';
}


/// This matches GetIt's exact API where instance can be called with generic parameters
class NxLocatorCallable {
  final NxLocator _locator;

  NxLocatorCallable._(this._locator);

  /// Public access to the underlying NxLocator instance
  NxLocator get locator => _locator;

  /// Usage: NxLocator.instance<WithdrawalRepository>()
  T call<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) {
    return _locator.get<T>(
      instanceName: instanceName,
      param1: param1,
      param2: param2,
    );
  }

  // Property-style access methods (for GetIt.instance.method() compatibility)

  /// Register a singleton - property access style
  /// Usage: NxLocator.instance.registerSingleton<Type>(instance)
  NxLocatorCallable registerSingleton<T extends Object>(
    T instance, {
    String? instanceName,
    String? profileName,
    RegistrationOptions<T>? options,
    bool? signalReady,
  }) {
    _locator.registerSingleton<T>(
      instance,
      instanceName: instanceName,
      profileName: profileName,
      options: options,
      signalReady: signalReady,
    );
    return this;
  }

  /// Register a lazy singleton - property access style
  NxLocatorCallable registerLazySingleton<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
    String? profileName,
    RegistrationOptions<T>? options,
  }) {
    _locator.registerLazySingleton<T>(
      factoryFunc,
      instanceName: instanceName,
      profileName: profileName,
      options: options,
    );
    return this;
  }

  /// Register an async singleton - property access style
  NxLocatorCallable registerSingletonAsync<T extends Object>(
    FactoryFuncAsync<T> factoryFunc, {
    String? instanceName,
    String? profileName,
    RegistrationOptions<T>? options,
  }) {
    _locator.registerSingletonAsync<T>(
      factoryFunc,
      instanceName: instanceName,
      profileName: profileName,
      options: options,
    );
    return this;
  }

  /// Register a factory - property access style
  NxLocatorCallable registerFactory<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
    String? profileName,
    RegistrationOptions<T>? options,
  }) {
    _locator.registerFactory<T>(
      factoryFunc,
      instanceName: instanceName,
      profileName: profileName,
      options: options,
    );
    return this;
  }

  /// Register a parameterized factory - property access style
  NxLocatorCallable registerFactoryParam<T extends Object, P1>(
    FactoryFuncParam<T, P1> factoryFunc, {
    String? instanceName,
    String? profileName,
    RegistrationOptions<T>? options,
  }) {
    _locator.registerFactoryParam<T, P1>(
      factoryFunc,
      instanceName: instanceName,
      profileName: profileName,
      options: options,
    );
    return this;
  }

  /// Register a factory with 2 parameters - property access style
  NxLocatorCallable registerFactoryParam2<T extends Object, P1, P2>(
    FactoryFuncParam2<T, P1, P2> factoryFunc, {
    String? instanceName,
    String? profileName,
    RegistrationOptions<T>? options,
  }) {
    _locator.registerFactoryParam2<T, P1, P2>(
      factoryFunc,
      instanceName: instanceName,
      profileName: profileName,
      options: options,
    );
    return this;
  }

  /// Get service - property access style
  T get<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) {
    return _locator.get<T>(
      instanceName: instanceName,
      param1: param1,
      param2: param2,
    );
  }

  /// Try to get service - property access style
  T? tryGet<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) {
    return _locator.tryGet<T>(
      instanceName: instanceName,
      param1: param1,
      param2: param2,
    );
  }

  /// Get service asynchronously - property access style
  Future<T> getAsync<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) {
    return _locator.getAsync<T>(
      instanceName: instanceName,
      param1: param1,
      param2: param2,
    );
  }

  /// Check if service is registered - property access style
  bool isRegistered<T extends Object>({
    String? instanceName,
    String? profileName,
  }) {
    return _locator.isRegistered<T>(
      instanceName: instanceName,
      profileName: profileName,
    );
  }

  /// Reset the locator - property access style
  Future<void> reset({bool dispose = true}) {
    return _locator.reset(dispose: dispose);
  }

  /// Unregister a service - property access style
  Future<bool> unregister<T extends Object>({
    String? instanceName,
    String? profileName,
    bool disposeDependency = true,
  }) {
    return _locator.unregister<T>(
      instanceName: instanceName,
      profileName: profileName,
      disposeDependency: disposeDependency,
    );
  }

  // Profile management methods
  Profile createProfile({
    required String name,
    String? description,
    int priority = 0,
    List<String> dependsOn = const [],
  }) {
    return _locator.createProfile(
      name: name,
      description: description,
      priority: priority,
      dependsOn: dependsOn,
    );
  }

  Future<void> activateProfile(String profileName) {
    return _locator.activateProfile(profileName);
  }

  Future<void> deactivateProfile(String profileName, {bool dispose = true}) {
    return _locator.deactivateProfile(profileName, dispose: dispose);
  }
}
