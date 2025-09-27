/// Interface for objects that can dispose themselves
abstract class Disposable {
  /// Dispose any resources held by this object
  void dispose();
}

/// Interface for objects that can dispose themselves asynchronously
abstract class AsyncDisposable {
  /// Asynchronously dispose any resources held by this object
  Future<void> dispose();
}

/// Result of a dependency resolution attempt
class DependencyResolutionResult<T extends Object> {
  /// The resolved instance (null if resolution failed)
  final T? instance;

  /// The profile that provided this instance
  final String? sourceProfile;

  /// Whether the resolution was successful
  final bool wasResolved;

  /// Error that occurred during resolution (if any)
  final Exception? error;

  /// Resolution time in microseconds
  final int resolutionTimeUs;

  const DependencyResolutionResult._({
    this.instance,
    this.sourceProfile,
    required this.wasResolved,
    this.error,
    this.resolutionTimeUs = 0,
  });

  /// Create a successful resolution result
  factory DependencyResolutionResult.success(
    T instance,
    String sourceProfile, {
    int resolutionTimeUs = 0,
  }) {
    return DependencyResolutionResult._(
      instance: instance,
      sourceProfile: sourceProfile,
      wasResolved: true,
      resolutionTimeUs: resolutionTimeUs,
    );
  }

  /// Create a failed resolution result
  factory DependencyResolutionResult.failure(
    Exception error, {
    int resolutionTimeUs = 0,
  }) {
    return DependencyResolutionResult._(
      wasResolved: false,
      error: error,
      resolutionTimeUs: resolutionTimeUs,
    );
  }

  /// Whether the resolution was successful
  bool get isSuccess => wasResolved && error == null;

  /// Whether the resolution failed
  bool get isFailure => !wasResolved || error != null;

  @override
  String toString() => isSuccess
      ? 'Success: ${instance.runtimeType} from $sourceProfile ($resolutionTimeUsμs)'
      : 'Failure: $error ($resolutionTimeUsμs)';
}

/// Strategy for disposing dependencies
enum DisposalStrategy {
  /// Don't dispose automatically - manual disposal required
  manual,

  /// Dispose when the profile containing this dependency is deactivated
  onProfileDeactivation,

  /// Dispose when the dependency is explicitly unregistered
  onUnregister,

  /// Dispose when NxLocator is reset completely
  onReset,

  /// Dispose when the application is shutting down
  onAppShutdown,
}

/// Information about a disposal operation
class DisposalInfo {
  /// The type of object being disposed
  final Type objectType;

  /// Instance name (if any)
  final String? instanceName;

  /// Profile that contained this dependency
  final String profileName;

  /// Disposal strategy that was used
  final DisposalStrategy strategy;

  /// Whether disposal completed successfully
  final bool wasSuccessful;

  /// Error that occurred during disposal (if any)
  final Exception? error;

  /// Time taken for disposal in microseconds
  final int disposalTimeUs;

  const DisposalInfo({
    required this.objectType,
    this.instanceName,
    required this.profileName,
    required this.strategy,
    required this.wasSuccessful,
    this.error,
    this.disposalTimeUs = 0,
  });

  @override
  String toString() => wasSuccessful
      ? 'Disposed: $objectType${instanceName != null ? '("$instanceName")' : ''} '
            'from $profileName using $strategy ($disposalTimeUsμs)'
      : 'Failed to dispose: $objectType - $error ($disposalTimeUsμs)';
}
