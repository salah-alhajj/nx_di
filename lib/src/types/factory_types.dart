// import 'package:meta/meta.dart';

/// Factory function that creates an instance of [T]
typedef FactoryFunc<T extends Object> = T Function();

/// Factory function that creates an instance of [T] with one parameter
typedef FactoryFuncParam<T extends Object, P1> = T Function(P1 param1);

/// Factory function that creates an instance of [T] with two parameters
typedef FactoryFuncParam2<T extends Object, P1, P2> =
    T Function(P1 param1, P2 param2);

/// Async factory function that creates an instance of [T]
typedef FactoryFuncAsync<T extends Object> = Future<T> Function();

/// Async factory function that creates an instance of [T] with one parameter
typedef FactoryFuncParamAsync<T extends Object, P1> =
    Future<T> Function(P1 param1);

/// Async factory function that creates an instance of [T] with two parameters
typedef FactoryFuncParam2Async<T extends Object, P1, P2> =
    Future<T> Function(P1 param1, P2 param2);

/// Signature for disposing objects
typedef DisposeFunc<T extends Object> = void Function(T instance);

/// Signature for async disposing objects
typedef DisposeFuncAsync<T extends Object> = Future<void> Function(T instance);

/// Signature for dependency change notifications
typedef DependencyChangeCallback<T extends Object> =
    void Function(T? oldInstance, T? newInstance);

/// Signature for profile change notifications
typedef ProfileChangeCallback =
    void Function(String profileName, ProfileChangeType changeType);

/// Types of profile changes for notifications
enum ProfileChangeType {
  /// Profile was activated
  activated,

  /// Profile was deactivated
  deactivated,

  /// A dependency was resolved from this profile
  dependencyResolved,

  /// A new dependency was registered in this profile
  dependencyRegistered,

  /// A dependency was unregistered from this profile
  dependencyUnregistered,

  /// Profile priority was changed
  priorityChanged,

  /// Profile dependencies were modified
  dependenciesChanged,
}

/// Signature for service ready notifications
/// Called when a service is registered and ready to be used
typedef ServiceReadyCallback<T extends Object> = void Function(T instance);

/// Signature for validation callbacks
/// Return true if validation passes, false otherwise
typedef ValidationCallback<T extends Object> = bool Function(T instance);

/// Signature for initialization callbacks
/// Called after a service is created but before it's returned
typedef InitializationCallback<T extends Object> = void Function(T instance);

/// Signature for finalization callbacks
/// Called before a service is disposed
typedef FinalizationCallback<T extends Object> = void Function(T instance);
