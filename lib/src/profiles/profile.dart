// src/profiles/profile.dart

import '../core/registration_options.dart';
import '../types/factory_types.dart';
import '../types/disposal_types.dart';
import '../exceptions/locator_exceptions.dart';
import '../core/nx_performance_optimizations.dart';

/// A dependency profile that manages a collection of services
class Profile {
  /// Unique name for this profile
  final String name;

  /// Optional description of what this profile contains
  final String? description;

  /// Priority for resolution order (higher priority = resolved first)
  final int priority;

  /// List of profile names this profile depends on
  final List<String> dependsOn;

  /// Whether this profile is currently active
  bool _isActive = false;

  /// Internal service registry
  final Map<ServiceKey, _ServiceRegistration> _services = {};

  /// Storage for ultra-fast lazy singletons
  final Map<ServiceKey, FastLazyRegistration> _fastServices = {};

  /// Type to instance names mapping for quick lookup
  final Map<Type, Set<String>> _typeToInstanceNames = {};

  /// Performance tracking
  final Map<Type, int> _accessCounts = {};
  final Map<Type, DateTime> _lastAccessed = {};

  Profile({
    required this.name,
    this.description,
    this.priority = 0,
    this.dependsOn = const [],
  });

  /// Whether this profile is currently active
  bool get isActive => _isActive;

  /// FIXED: Add public setter for ProfileManager to use
  /// Internal setter for active status (used by ProfileManager)
  set isActive(bool value) => _isActive = value;

  /// Alternative method-based approach for setting active status
  void setActiveStatus(bool active) => _isActive = active;

  /// Get all registered service types in this profile
  Iterable<Type> get registeredTypes =>
      _services.keys.map((key) => key.type).toSet();

  /// Get number of registered services
  int get serviceCount => _services.length + _fastServices.length;

  /// Get all instance names for a specific type
  Set<String> getInstanceNamesForType<T extends Object>() {
    return _typeToInstanceNames[T]?.toSet() ?? <String>{};
  }

  /// Check if a service is registered in this profile
  bool isRegistered<T extends Object>({String? instanceName}) {
    final key = ServiceKey.cached(T, instanceName); // 2025 OPTIMIZATION
    return _services.containsKey(key) || _fastServices.containsKey(key);
  }

  /// Ultra-fast lazy singleton with minimal validation overhead
  void registerFastLazySingleton<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
  }) {
    final key = ServiceKey.cached(T, instanceName);
    if (_services.containsKey(key) || _fastServices.containsKey(key)) {
      throw Exception(
        'Service of type $T${instanceName != null ? ' with name "$instanceName"' : ''} is already registered',
      );
    }
    _fastServices[key] = FastLazyRegistration<T>(factoryFunc);
    _addToTypeMapping<T>(instanceName);
  }

  /// Register a factory function that creates a new instance each time
  void registerFactory<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
    RegistrationOptions<T>? options,
  }) {
    final key = ServiceKey.cached(T, instanceName); // 2025 OPTIMIZATION
    final effectiveOptions = options ?? RegistrationOptions<T>();

    _checkAlreadyRegistered<T>(key, instanceName, effectiveOptions);

    final registration = _ServiceRegistration<T>(
      factoryFunc: factoryFunc,
      registrationType: _RegistrationType.factory,
      options: effectiveOptions,
    );

    _registerService(key, registration, instanceName);
  }

  /// Register a factory function that creates instance only once (lazy singleton)
  void registerLazySingleton<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
    RegistrationOptions<T>? options,
  }) {
    final key = ServiceKey.cached(T, instanceName); // 2025 OPTIMIZATION

    // Ultra-fast path for common case (no options) - 2025 ENHANCEMENT
    if (options == null) {
      registerFastLazySingleton<T>(factoryFunc, instanceName: instanceName);
      return;
    }

    // Standard path when options are provided
    final effectiveOptions = options;
    if (!effectiveOptions.allowOverride &&
        (_services.containsKey(key) || _fastServices.containsKey(key))) {
      throw Exception(
        'Service of type $T${instanceName != null ? ' with name "$instanceName"' : ''} is already registered',
      );
    }

    _services[key] = _ServiceRegistration<T>(
      factoryFunc: factoryFunc,
      registrationType: _RegistrationType.lazySingleton,
      options: effectiveOptions,
    );

    if (instanceName != null) {
      _typeToInstanceNames.putIfAbsent(T, () => <String>{}).add(instanceName);
    }
  }

  // 2025 CONST LOOKUP: Pre-computed hash tables for maximum compiler optimization
  static const Map<Type, int> _typeHashCache = <Type, int>{
    String: 67452301, // Pre-computed hash for String type
    int: 19, // Pre-computed hash for int type
    double: 314159, // Pre-computed hash for double type (integer value)
    bool: 42, // Pre-computed hash for bool type
    List: 1337, // Pre-computed hash for List type
  };

  // 2025 MEMORY OPTIMIZATION: Object pools to reduce allocations
  static final List<Set<String>> _stringSetPool = [];
  static const int _maxPoolSize = 50;

  // Get pooled set to reduce memory allocations
  static Set<String> _getPooledStringSet() {
    if (_stringSetPool.isNotEmpty) {
      final set = _stringSetPool.removeLast();
      set.clear();
      return set;
    }
    return <String>{};
  }

  // Return set to pool for reuse
  static void _returnPooledStringSet(Set<String> set) {
    if (_stringSetPool.length < _maxPoolSize) {
      _stringSetPool.add(set);
    }
  }

  /// Register an existing instance as a singleton
  void registerSingleton<T extends Object>(
    T instance, {
    String? instanceName,
    RegistrationOptions<T>? options,
  }) {
    final key = ServiceKey.cached(T, instanceName); // 2025 OPTIMIZATION
    final effectiveOptions = options ?? RegistrationOptions<T>();

    _checkAlreadyRegistered<T>(key, instanceName, effectiveOptions);

    final registration = _ServiceRegistration<T>(
      instance: instance,
      registrationType: _RegistrationType.singleton,
      options: effectiveOptions,
    );

    _registerService(key, registration, instanceName);

    // Call initialization callback if provided
    effectiveOptions.onInitialized?.call(instance);

    // Signal ready if requested
    if (effectiveOptions.signalReady) {
      effectiveOptions.onReady?.call(instance);
    }
  }

  /// Register an async factory function as a singleton
  void registerSingletonAsync<T extends Object>(
    FactoryFuncAsync<T> factoryFunc, {
    String? instanceName,
    RegistrationOptions<T>? options,
  }) {
    final key = ServiceKey.cached(T, instanceName); // 2025 OPTIMIZATION
    final effectiveOptions = options ?? RegistrationOptions<T>();

    _checkAlreadyRegistered<T>(key, instanceName, effectiveOptions);

    final registration = _ServiceRegistration<T>(
      factoryFuncAsync: factoryFunc,
      registrationType: _RegistrationType.singletonAsync,
      options: effectiveOptions,
    );

    _registerService(key, registration, instanceName);
  }

  /// Register a factory function with one parameter
  void registerFactoryParam<T extends Object, P1>(
    FactoryFuncParam<T, P1> factoryFunc, {
    String? instanceName,
    RegistrationOptions<T>? options,
  }) {
    final key = ServiceKey.cached(T, instanceName); // 2025 OPTIMIZATION
    final effectiveOptions = options ?? RegistrationOptions<T>();

    _checkAlreadyRegistered<T>(key, instanceName, effectiveOptions);

    final registration = _ServiceRegistration<T>(
      factoryFuncParam: factoryFunc,
      registrationType: _RegistrationType.factoryParam,
      options: effectiveOptions,
    );

    _registerService(key, registration, instanceName);
  }

  /// Register a factory function with two parameters
  void registerFactoryParam2<T extends Object, P1, P2>(
    FactoryFuncParam2<T, P1, P2> factoryFunc, {
    String? instanceName,
    RegistrationOptions<T>? options,
  }) {
    final key = ServiceKey.cached(T, instanceName); // 2025 OPTIMIZATION
    final effectiveOptions = options ?? RegistrationOptions<T>();

    _checkAlreadyRegistered<T>(key, instanceName, effectiveOptions);

    final registration = _ServiceRegistration<T>(
      factoryFuncParam2: factoryFunc,
      registrationType: _RegistrationType.factoryParam2,
      options: effectiveOptions,
    );

    _registerService(key, registration, instanceName);
  }

  /// Try to get a service instance (returns null if not found)
  T? tryGet<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) {
    try {
      return get<T>(instanceName: instanceName, param1: param1, param2: param2);
    } catch (_) {
      return null;
    }
  }

  /// Fast service resolution for lazy singletons
  T? getFastLazy<T extends Object>({String? instanceName}) {
    final key = ServiceKey.cached(T, instanceName);
    final registration = _fastServices[key] as FastLazyRegistration<T>?;

    if (registration == null) return null;

    // Ultra-fast lazy instantiation
    return registration.getInstance();
  }

  /// Get a service instance - 2025 MINIMALIST for pure speed
  T get<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) {
    final key = ServiceKey.cached(T, instanceName);

    // Check fast services first
    final fastRegistration = _fastServices[key] as FastLazyRegistration<T>?;
    if (fastRegistration != null) {
      return fastRegistration.getInstance();
    }

    final registration = _services[key] as _ServiceRegistration<T>?;

    if (registration == null) {
      throw ObjectNotFoundException(
        'Object of type ${T.toString()} is not registered in profile "$name"',
        objectType: T,
        instanceName: instanceName,
        searchedProfiles: [name],
      );
    }

    final instance = registration.getInstance(param1: param1, param2: param2);

    // Simple access counting
    _accessCounts[T] = (_accessCounts[T] ?? 0) + 1;

    return instance;
  }

  /// Get a service instance asynchronously
  Future<T> getAsync<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) async {
    final key = ServiceKey.cached(T, instanceName);
    final registration = _services[key] as _ServiceRegistration<T>?;

    if (registration == null) {
      throw ObjectNotFoundException(
        'Object of type ${T.toString()} is not registered in profile "$name"',
        objectType: T,
        instanceName: instanceName,
        searchedProfiles: [name],
      );
    }

    if (registration.registrationType == _RegistrationType.singletonAsync) {
      if (registration._instance == null) {
        registration._instance = await registration.factoryFuncAsync!();
      }
      return registration._instance as T;
    }

    final instance = registration.getInstance(param1: param1, param2: param2);

    // Simple access counting
    _accessCounts[T] = (_accessCounts[T] ?? 0) + 1;

    return instance;
  }

  /// Unregister a service from this profile
  bool unregister<T extends Object>({
    String? instanceName,
    bool disposeDependency = true,
  }) {
    final key = ServiceKey.cached(T, instanceName); // 2025 OPTIMIZATION
    final registration = _services.remove(key);
    final fastRegistration = _fastServices.remove(key);

    if (registration == null && fastRegistration == null) return false;

    if (disposeDependency) {
      try {
        registration?.dispose();
      } catch (e) {
        // Log error but don't prevent unregistration (using assert for development)
        assert(false, 'Warning: Failed to dispose ${T.toString()}: $e');
      }
    }

    _removeFromTypeMapping<T>(instanceName);
    return true;
  }

  /// Clear all services in this profile
  Future<void> clear({bool dispose = true}) async {
    if (dispose) {
      // Ultra-fast synchronous disposal path
      _clearServicesSync();
    } else {
      // Skip disposal entirely - just clear references
      _services.clear();
      _fastServices.clear();
      _typeToInstanceNames.clear();
      _accessCounts.clear();
      _lastAccessed.clear();
    }
  }

  /// Synchronous service clearing for maximum performance
  void _clearServicesSync() {
    // Group services by disposal type for batch processing
    final syncDisposables = <Disposable>[];
    final asyncDisposables = <AsyncDisposable>[];

    for (final registration in _services.values) {
      final instance = registration._instance;
      if (instance != null) {
        if (instance is AsyncDisposable) {
          asyncDisposables.add(instance);
        } else if (instance is Disposable) {
          syncDisposables.add(instance);
        }
      }
    }

    // Dispose synchronous services immediately (no try-catch for speed)
    for (final disposable in syncDisposables) {
      disposable.dispose();
    }

    // For async disposables, fire-and-forget (don't await)
    for (final asyncDisposable in asyncDisposables) {
      asyncDisposable.dispose().catchError((_) {}); // Ignore errors
    }

    // Clear all data structures
    _services.clear();
    _fastServices.clear();
    _typeToInstanceNames.clear();
    _accessCounts.clear();
    _lastAccessed.clear();
  }

  /// Ultra-fast clear without any disposal (for benchmarks) - 2025 ULTIMATE
  void clearFast() {
    _services.clear();
    _fastServices.clear();
    _typeToInstanceNames.clear();
    _accessCounts.clear();
    _lastAccessed.clear();
  }

  /// Get performance statistics for this profile
  Map<String, dynamic> getPerformanceStats() {
    final totalAccesses = _accessCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final mostAccessed =
        _accessCounts.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'profile_name': name,
      'service_count': serviceCount,
      'total_accesses': totalAccesses,
      'most_accessed_services': mostAccessed
          .take(5)
          .map((e) => {'type': e.key.toString(), 'accesses': e.value})
          .toList(),
      'is_active': isActive,
    };
  }

  // Internal methods

  void _registerService<T extends Object>(
    ServiceKey key,
    _ServiceRegistration<T> registration,
    String? instanceName,
  ) {
    _services[key] = registration;
    _addToTypeMapping<T>(instanceName);
  }

  void _checkAlreadyRegistered<T extends Object>(
    ServiceKey key,
    String? instanceName,
    RegistrationOptions<T> options,
  ) {
    if ((_services.containsKey(key) || _fastServices.containsKey(key)) &&
        !options.allowOverride) {
      throw ObjectAlreadyRegisteredException(
        'Object of type ${T.toString()} is already registered',
        objectType: T,
        instanceName: instanceName,
        profileName: name,
      );
    }
  }

  void _addToTypeMapping<T extends Object>(String? instanceName) {
    // 2025 OPTIMIZATION: Use object pooling for memory efficiency
    final names = _typeToInstanceNames.putIfAbsent(
      T,
      () => _getPooledStringSet(),
    );
    names.add(instanceName ?? '');
  }

  void _removeFromTypeMapping<T extends Object>(String? instanceName) {
    final names = _typeToInstanceNames[T];
    if (names != null) {
      names.remove(instanceName ?? '');
      if (names.isEmpty) {
        // 2025 OPTIMIZATION: Return set to pool for reuse
        _returnPooledStringSet(names);
        _typeToInstanceNames.remove(T);
      }
    }
  }

  /// Internal method to get registration (for advanced usage) - 2025 ENHANCED
  Object? getRegistration<T extends Object>({String? instanceName}) {
    final key = ServiceKey.cached(T, instanceName); // 2025 OPTIMIZATION
    return _services[key] ?? _fastServices[key];
  }

  @override
  String toString() =>
      'Profile(name: $name, active: $isActive, '
      'services: $serviceCount, priority: $priority)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

// Internal classes

/// Internal key for service lookup - 2025 COMPILE-TIME OPTIMIZED
class ServiceKey {
  final Type type;
  final String? instanceName;
  final int _precomputedHashCode;

  // 2025 OPTIMIZATION: Pre-compute hash code for maximum performance
  ServiceKey(this.type, this.instanceName)
    : _precomputedHashCode = _computeHashCode(type, instanceName);

  const ServiceKey._(this.type, this.instanceName, this._precomputedHashCode);

  // Const factory for common types (compile-time optimization)
  factory ServiceKey.cached(Type type, String? instanceName) {
    final typeHash = Profile._typeHashCache[type];
    if (typeHash != null) {
      // Use pre-computed hash for common types
      return ServiceKey._(
        type,
        instanceName,
        typeHash ^ (instanceName?.hashCode ?? 0),
      );
    }
    return ServiceKey(type, instanceName);
  }

  static int _computeHashCode(Type type, String? instanceName) {
    return type.hashCode ^ (instanceName?.hashCode ?? 0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceKey &&
          _precomputedHashCode == other._precomputedHashCode &&
          type == other.type &&
          instanceName == other.instanceName;

  @override
  int get hashCode => _precomputedHashCode;

  @override
  String toString() => 'ServiceKey(type: $type, instanceName: $instanceName)';
}

/// Types of service registrations
enum _RegistrationType {
  factory,
  lazySingleton,
  singleton,
  singletonAsync, // Added for async singletons
  factoryParam,
  factoryParam2,
}

/// Internal service registration
class _ServiceRegistration<T extends Object> {
  final FactoryFunc<T>? factoryFunc;
  final FactoryFuncAsync<T>? factoryFuncAsync; // Added for async factories
  final Function? factoryFuncParam;
  final Function? factoryFuncParam2;
  final _RegistrationType registrationType;
  final RegistrationOptions<T> options;

  T? _instance;
  bool _isDisposed = false;

  _ServiceRegistration({
    this.factoryFunc,
    this.factoryFuncAsync,
    this.factoryFuncParam,
    this.factoryFuncParam2,
    T? instance,
    required this.registrationType,
    required this.options,
  }) : _instance = instance;

  T getInstance({dynamic param1, dynamic param2}) {
    if (_isDisposed) {
      throw StateError('Service has been disposed');
    }

    final T instance;

    switch (registrationType) {
      case _RegistrationType.factory:
        instance = factoryFunc!();
        break;

      case _RegistrationType.singletonAsync:
        throw StateError(
          'Cannot get an async singleton with a sync method. Use getAsync instead.',
        );

      case _RegistrationType.lazySingleton:
        // Ultra-fast lazy instantiation: minimize all overhead
        if (_instance == null) {
          _instance = factoryFunc!();
          // Only execute callbacks if they're actually set
          final onInit = options.onInitialized;
          if (onInit != null) {
            onInit(_instance as T);
            if (options.signalReady) {
              options.onReady?.call(_instance as T);
            }
          }
        }
        instance = _instance!;
        break;

      case _RegistrationType.singleton:
        instance = _instance!;
        break;

      case _RegistrationType.factoryParam:
        instance = (factoryFuncParam as Function)(param1);
        break;

      case _RegistrationType.factoryParam2:
        instance = (factoryFuncParam2 as Function)(param1, param2);
        break;
    }

    // Fast path: skip validation unless explicitly provided
    if (options.validator != null && !options.validator!(instance)) {
      throw ValidationException(
        'Instance validation failed for type ${T.toString()}',
        objectType: T,
        profileName: 'unknown', // Will be set by caller
      );
    }

    return instance;
  }

  Future<void> dispose() async {
    if (_isDisposed || _instance == null) return;

    final instanceToDispose = _instance!;
    _isDisposed = true;

    try {
      // Call finalization callback if provided
      options.onFinalized?.call(instanceToDispose);

      // Custom dispose function takes precedence
      if (options.asyncDisposeFunction != null) {
        await options.asyncDisposeFunction!(instanceToDispose);
      } else if (options.disposeFunction != null) {
        options.disposeFunction!(instanceToDispose);
      }
      // Check if instance implements disposal interfaces
      else if (instanceToDispose is AsyncDisposable) {
        await instanceToDispose.dispose();
      } else if (instanceToDispose is Disposable) {
        instanceToDispose.dispose();
      }
    } catch (e) {
      throw DisposalException(
        'Failed to dispose instance: $e',
        objectType: T,
        innerException: e,
      );
    } finally {
      _instance = null;
    }
  }
}
