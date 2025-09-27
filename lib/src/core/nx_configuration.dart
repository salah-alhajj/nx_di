// src/core/nx_configuration.dart

import '../types/factory_types.dart';

/// Environment configuration for NxLocator
enum NxEnvironment {
  /// Development environment
  development,

  /// Testing environment
  testing,

  /// Production environment
  production,

  /// Custom environment
  custom,
}

/// Performance configuration for NxLocator
class NxPerformanceConfig {
  /// Whether to enable performance tracking
  final bool enablePerformanceTracking;

  /// Whether to cache dependency resolution results
  final bool enableResolutionCaching;

  /// Maximum size of the resolution cache
  final int maxCacheSize;

  /// Whether to enable lazy loading for singletons
  final bool enableLazyLoading;

  /// Whether to enable asynchronous initialization
  final bool enableAsyncInit;

  const NxPerformanceConfig({
    this.enablePerformanceTracking = true,
    this.enableResolutionCaching = true,
    this.maxCacheSize = 1000,
    this.enableLazyLoading = true,
    this.enableAsyncInit = false,
  });

  /// Development-optimized configuration
  factory NxPerformanceConfig.development() {
    return const NxPerformanceConfig(
      enablePerformanceTracking: true,
      enableResolutionCaching: false, // Disable for easier debugging
      maxCacheSize: 100,
      enableLazyLoading: false, // Eager loading for faster debugging
      enableAsyncInit: false,
    );
  }

  /// Production-optimized configuration
  factory NxPerformanceConfig.production() {
    return const NxPerformanceConfig(
      enablePerformanceTracking: false, // Reduce overhead
      enableResolutionCaching: true,
      maxCacheSize: 5000,
      enableLazyLoading: true,
      enableAsyncInit: true,
    );
  }

  /// Testing-optimized configuration
  factory NxPerformanceConfig.testing() {
    return const NxPerformanceConfig(
      enablePerformanceTracking: false,
      enableResolutionCaching: false, // Avoid state pollution between tests
      maxCacheSize: 0,
      enableLazyLoading: false, // Predictable test behavior
      enableAsyncInit: false,
    );
  }
}

/// Validation configuration for NxLocator
class NxValidationConfig {
  /// Whether to validate circular dependencies
  final bool validateCircularDependencies;

  /// Whether to validate profile dependencies at registration
  final bool validateProfileDependencies;

  /// Whether to validate service interfaces
  final bool validateServiceInterfaces;

  /// Whether to enable strict mode (throws on warnings)
  final bool strictMode;

  /// Custom validation callbacks
  final Map<Type, ValidationCallback> customValidators;

  const NxValidationConfig({
    this.validateCircularDependencies = true,
    this.validateProfileDependencies = true,
    this.validateServiceInterfaces = false,
    this.strictMode = false,
    this.customValidators = const {},
  });

  /// Development configuration with extensive validation
  factory NxValidationConfig.development() {
    return const NxValidationConfig(
      validateCircularDependencies: true,
      validateProfileDependencies: true,
      validateServiceInterfaces: true,
      strictMode: true,
    );
  }

  /// Production configuration with minimal validation
  factory NxValidationConfig.production() {
    return const NxValidationConfig(
      validateCircularDependencies: true, // Keep for safety
      validateProfileDependencies: false, // Assume validated in dev/test
      validateServiceInterfaces: false,
      strictMode: false,
    );
  }

  /// Testing configuration
  factory NxValidationConfig.testing() {
    return const NxValidationConfig(
      validateCircularDependencies: true,
      validateProfileDependencies: true,
      validateServiceInterfaces: false, // May interfere with mocks
      strictMode: true,
    );
  }
}

/// Logging configuration for NxLocator
class NxLoggingConfig {
  /// Whether to enable debug logging
  final bool enableDebugLogging;

  /// Whether to log performance metrics
  final bool logPerformanceMetrics;

  /// Whether to log profile operations
  final bool logProfileOperations;

  /// Whether to log dependency resolutions
  final bool logDependencyResolutions;

  /// Custom log handler
  final void Function(String level, String message, [Object? error])?
  logHandler;

  const NxLoggingConfig({
    this.enableDebugLogging = false,
    this.logPerformanceMetrics = false,
    this.logProfileOperations = false,
    this.logDependencyResolutions = false,
    this.logHandler,
  });

  /// Development logging configuration
  factory NxLoggingConfig.development() {
    return NxLoggingConfig(
      enableDebugLogging: true,
      logPerformanceMetrics: true,
      logProfileOperations: true,
      logDependencyResolutions: true,
      logHandler: (level, message, [error]) {
        print('[$level] NxDI: $message${error != null ? ' - $error' : ''}');
      },
    );
  }

  /// Production logging configuration
  factory NxLoggingConfig.production() {
    return const NxLoggingConfig(
      enableDebugLogging: false,
      logPerformanceMetrics: false,
      logProfileOperations: false,
      logDependencyResolutions: false,
    );
  }

  /// Testing logging configuration
  factory NxLoggingConfig.testing() {
    return const NxLoggingConfig(
      enableDebugLogging: false, // Keep tests clean
      logPerformanceMetrics: false,
      logProfileOperations: false,
      logDependencyResolutions: false,
    );
  }
}

/// Complete configuration for NxLocator
class NxConfiguration {
  /// Current environment
  final NxEnvironment environment;

  /// Performance configuration
  final NxPerformanceConfig performance;

  /// Validation configuration
  final NxValidationConfig validation;

  /// Logging configuration
  final NxLoggingConfig logging;

  /// Custom environment name (when using NxEnvironment.custom)
  final String? customEnvironmentName;

  const NxConfiguration({
    this.environment = NxEnvironment.production,
    this.performance = const NxPerformanceConfig(),
    this.validation = const NxValidationConfig(),
    this.logging = const NxLoggingConfig(),
    this.customEnvironmentName,
  });

  /// Create a development-optimized configuration
  factory NxConfiguration.development() {
    return NxConfiguration(
      environment: NxEnvironment.development,
      performance: NxPerformanceConfig.development(),
      validation: NxValidationConfig.development(),
      logging: NxLoggingConfig.development(),
    );
  }

  /// Create a production-optimized configuration
  factory NxConfiguration.production() {
    return NxConfiguration(
      environment: NxEnvironment.production,
      performance: NxPerformanceConfig.production(),
      validation: NxValidationConfig.production(),
      logging: NxLoggingConfig.production(),
    );
  }

  /// Create a testing-optimized configuration
  factory NxConfiguration.testing() {
    return NxConfiguration(
      environment: NxEnvironment.testing,
      performance: NxPerformanceConfig.testing(),
      validation: NxValidationConfig.testing(),
      logging: NxLoggingConfig.testing(),
    );
  }

  /// Create a custom configuration
  factory NxConfiguration.custom({
    required String environmentName,
    NxPerformanceConfig? performance,
    NxValidationConfig? validation,
    NxLoggingConfig? logging,
  }) {
    return NxConfiguration(
      environment: NxEnvironment.custom,
      customEnvironmentName: environmentName,
      performance: performance ?? const NxPerformanceConfig(),
      validation: validation ?? const NxValidationConfig(),
      logging: logging ?? const NxLoggingConfig(),
    );
  }

  /// Get environment name
  String get environmentName {
    switch (environment) {
      case NxEnvironment.development:
        return 'development';
      case NxEnvironment.testing:
        return 'testing';
      case NxEnvironment.production:
        return 'production';
      case NxEnvironment.custom:
        return customEnvironmentName ?? 'custom';
    }
  }

  /// Whether this is a development environment
  bool get isDevelopment => environment == NxEnvironment.development;

  /// Whether this is a production environment
  bool get isProduction => environment == NxEnvironment.production;

  /// Whether this is a testing environment
  bool get isTesting => environment == NxEnvironment.testing;

  @override
  String toString() => 'NxConfiguration(environment: $environmentName)';
}
