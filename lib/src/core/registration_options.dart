// src/core/registration_options.dart

import '../types/factory_types.dart';
import '../types/disposal_types.dart';

/// Configuration options for service registration
class RegistrationOptions<T extends Object> {
  /// Whether to allow overriding an existing registration
  final bool allowOverride;

  /// Whether to signal that the service is ready after registration
  final bool signalReady;

  /// Custom disposal function (takes precedence over interfaces)
  final DisposeFunc<T>? disposeFunction;

  /// Custom async disposal function (takes precedence over interfaces)
  final DisposeFuncAsync<T>? asyncDisposeFunction;

  /// Disposal strategy to use for this registration
  final DisposalStrategy disposalStrategy;

  /// Callback when service is ready
  final ServiceReadyCallback<T>? onReady;

  /// Callback for service initialization
  final InitializationCallback<T>? onInitialized;

  /// Callback for service finalization (before disposal)
  final FinalizationCallback<T>? onFinalized;

  /// Validation function to run on created instances
  final ValidationCallback<T>? validator;

  /// Whether to enable dependency tracking for this registration
  final bool trackDependencies;

  /// Whether to cache factory results for better performance
  final bool cacheFactory;

  /// Custom metadata for this registration
  final Map<String, dynamic>? metadata;

  // FIXED: Removed const constructor - generic classes can't have const constructors
  RegistrationOptions({
    this.allowOverride = false,
    this.signalReady = false,
    this.disposeFunction,
    this.asyncDisposeFunction,
    this.disposalStrategy = DisposalStrategy.onProfileDeactivation,
    this.onReady,
    this.onInitialized,
    this.onFinalized,
    this.validator,
    this.trackDependencies = false,
    this.cacheFactory = false,
    this.metadata,
  });

  /// Create a copy of this options object with some fields changed
  RegistrationOptions<T> copyWith({
    bool? allowOverride,
    bool? signalReady,
    DisposeFunc<T>? disposeFunction,
    DisposeFuncAsync<T>? asyncDisposeFunction,
    DisposalStrategy? disposalStrategy,
    ServiceReadyCallback<T>? onReady,
    InitializationCallback<T>? onInitialized,
    FinalizationCallback<T>? onFinalized,
    ValidationCallback<T>? validator,
    bool? trackDependencies,
    bool? cacheFactory,
    Map<String, dynamic>? metadata,
  }) {
    return RegistrationOptions<T>(
      allowOverride: allowOverride ?? this.allowOverride,
      signalReady: signalReady ?? this.signalReady,
      disposeFunction: disposeFunction ?? this.disposeFunction,
      asyncDisposeFunction: asyncDisposeFunction ?? this.asyncDisposeFunction,
      disposalStrategy: disposalStrategy ?? this.disposalStrategy,
      onReady: onReady ?? this.onReady,
      onInitialized: onInitialized ?? this.onInitialized,
      onFinalized: onFinalized ?? this.onFinalized,
      validator: validator ?? this.validator,
      trackDependencies: trackDependencies ?? this.trackDependencies,
      cacheFactory: cacheFactory ?? this.cacheFactory,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Merge this options with another options object
  /// Other options take precedence for non-null values
  RegistrationOptions<T> merge(RegistrationOptions<T>? other) {
    if (other == null) return this;

    return copyWith(
      allowOverride: other.allowOverride,
      signalReady: other.signalReady,
      disposeFunction: other.disposeFunction,
      asyncDisposeFunction: other.asyncDisposeFunction,
      disposalStrategy: other.disposalStrategy,
      onReady: other.onReady,
      onInitialized: other.onInitialized,
      onFinalized: other.onFinalized,
      validator: other.validator,
      trackDependencies: other.trackDependencies,
      cacheFactory: other.cacheFactory,
      metadata: other.metadata != null
          ? {...?metadata, ...other.metadata!}
          : metadata,
    );
  }

  @override
  String toString() =>
      'RegistrationOptions<$T>('
      'allowOverride: $allowOverride, '
      'signalReady: $signalReady, '
      'disposalStrategy: $disposalStrategy, '
      'trackDependencies: $trackDependencies'
      ')';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegistrationOptions<T> &&
          runtimeType == other.runtimeType &&
          allowOverride == other.allowOverride &&
          signalReady == other.signalReady &&
          disposeFunction == other.disposeFunction &&
          asyncDisposeFunction == other.asyncDisposeFunction &&
          disposalStrategy == other.disposalStrategy &&
          onReady == other.onReady &&
          onInitialized == other.onInitialized &&
          onFinalized == other.onFinalized &&
          validator == other.validator &&
          trackDependencies == other.trackDependencies &&
          cacheFactory == other.cacheFactory;

  @override
  int get hashCode =>
      allowOverride.hashCode ^
      signalReady.hashCode ^
      disposeFunction.hashCode ^
      asyncDisposeFunction.hashCode ^
      disposalStrategy.hashCode ^
      onReady.hashCode ^
      onInitialized.hashCode ^
      onFinalized.hashCode ^
      validator.hashCode ^
      trackDependencies.hashCode ^
      cacheFactory.hashCode;
}

/// Predefined registration options for common scenarios
class RegistrationPresets {
  RegistrationPresets._(); // Prevent instantiation

  /// Standard singleton with automatic disposal
  static RegistrationOptions<T> singleton<T extends Object>() {
    return RegistrationOptions<T>(
      signalReady: true,
      disposalStrategy: DisposalStrategy.onProfileDeactivation,
    );
  }

  /// Factory that allows overriding existing registrations
  static RegistrationOptions<T> replaceableFactory<T extends Object>() {
    return RegistrationOptions<T>(
      allowOverride: true,
      disposalStrategy: DisposalStrategy.manual,
    );
  }

  /// Development/debug mode with tracking enabled
  static RegistrationOptions<T> debug<T extends Object>() {
    return RegistrationOptions<T>(trackDependencies: true, allowOverride: true);
  }

  /// High-performance cached factory
  static RegistrationOptions<T> cached<T extends Object>() {
    return RegistrationOptions<T>(
      cacheFactory: true,
      disposalStrategy: DisposalStrategy.onReset,
    );
  }
}
