// src/exceptions/locator_exceptions.dart

/// Base exception class for all nx_di related exceptions
abstract class NxDiException implements Exception {
  /// Human-readable error message
  final String message;

  /// Optional inner exception that caused this exception
  final Object? innerException;

  /// Stack trace from the inner exception
  final StackTrace? innerStackTrace;

  const NxDiException(
    this.message, {
    this.innerException,
    this.innerStackTrace,
  });

  @override
  String toString() => 'NxDiException: $message';
}

/// Thrown when a requested object cannot be found in any active profile
class ObjectNotFoundException extends NxDiException {
  /// The type that was requested but not found
  final Type objectType;

  /// Instance name that was requested (if any)
  final String? instanceName;

  /// List of profile names that were searched
  final List<String> searchedProfiles;

  const ObjectNotFoundException(
    super.message, {
    required this.objectType,
    this.instanceName,
    this.searchedProfiles = const [],
    super.innerException,
    super.innerStackTrace,
  });

  @override
  String toString() {
    final instanceInfo = instanceName != null
        ? ' with instance name "$instanceName"'
        : '';
    final profileInfo = searchedProfiles.isNotEmpty
        ? ' (searched profiles: ${searchedProfiles.join(", ")})'
        : '';
    return 'ObjectNotFoundException: Could not find ${objectType.toString()}$instanceInfo$profileInfo. $message';
  }
}

/// Thrown when attempting to register an object that is already registered
class ObjectAlreadyRegisteredException extends NxDiException {
  /// The type that was already registered
  final Type objectType;

  /// Instance name that was already registered (if any)
  final String? instanceName;

  /// Name of the profile where it was already registered
  final String? profileName;

  const ObjectAlreadyRegisteredException(
    super.message, {
    required this.objectType,
    this.instanceName,
    this.profileName,
    super.innerException,
    super.innerStackTrace,
  });

  @override
  String toString() {
    final instanceInfo = instanceName != null
        ? ' with instance name "$instanceName"'
        : '';
    final profileInfo = profileName != null ? ' in profile "$profileName"' : '';
    return 'ObjectAlreadyRegisteredException: ${objectType.toString()}$instanceInfo$profileInfo is already registered. $message';
  }
}

/// Thrown when a factory function fails to create an instance
class FactoryException extends NxDiException {
  /// The type that the factory was supposed to create
  final Type objectType;

  /// Instance name for the failed factory (if any)
  final String? instanceName;

  /// Name of the profile containing the factory
  final String? profileName;

  const FactoryException(
    super.message, {
    required this.objectType,
    this.instanceName,
    this.profileName,
    super.innerException,
    super.innerStackTrace,
  });

  @override
  String toString() {
    final instanceInfo = instanceName != null
        ? ' with instance name "$instanceName"'
        : '';
    final profileInfo = profileName != null ? ' in profile "$profileName"' : '';
    return 'FactoryException: Failed to create ${objectType.toString()}$instanceInfo$profileInfo. $message';
  }
}

/// Thrown when disposal of an object fails
class DisposalException extends NxDiException {
  /// The type that failed to dispose
  final Type objectType;

  /// Instance name for the failed disposal (if any)
  final String? instanceName;

  /// Name of the profile containing the object
  final String? profileName;

  const DisposalException(
    super.message, {
    required this.objectType,
    this.instanceName,
    this.profileName,
    super.innerException,
    super.innerStackTrace,
  });

  @override
  String toString() {
    final instanceInfo = instanceName != null
        ? ' with instance name "$instanceName"'
        : '';
    final profileInfo = profileName != null
        ? ' from profile "$profileName"'
        : '';
    return 'DisposalException: Failed to dispose ${objectType.toString()}$instanceInfo$profileInfo. $message';
  }
}

/// Thrown when profile-related operations fail
class ProfileException extends NxDiException {
  /// Name of the profile involved in the exception
  final String? profileName;

  /// List of related profile names (for dependency issues)
  final List<String> relatedProfiles;

  const ProfileException(
    super.message, {
    this.profileName,
    this.relatedProfiles = const [],
    super.innerException,
    super.innerStackTrace,
  });

  @override
  String toString() {
    final profileInfo = profileName != null ? ' (profile: "$profileName")' : '';
    final relatedInfo = relatedProfiles.isNotEmpty
        ? ' (related profiles: ${relatedProfiles.join(", ")})'
        : '';
    return 'ProfileException$profileInfo$relatedInfo: $message';
  }
}

/// Thrown when a circular dependency is detected
class CircularDependencyException extends NxDiException {
  /// The chain of dependencies that form the circular reference
  final List<Type> dependencyChain;

  /// Profile names involved in the circular dependency
  final List<String> profileChain;

  const CircularDependencyException(
    super.message, {
    this.dependencyChain = const [],
    this.profileChain = const [],
    super.innerException,
    super.innerStackTrace,
  });

  @override
  String toString() {
    final typeChain = dependencyChain.isNotEmpty
        ? ' Type chain: ${dependencyChain.map((t) => t.toString()).join(" -> ")}'
        : '';
    final profileChainInfo = profileChain.isNotEmpty
        ? ' Profile chain: ${profileChain.join(" -> ")}'
        : '';
    return 'CircularDependencyException: $message$typeChain$profileChainInfo';
  }
}

/// Thrown when validation of a created instance fails
class ValidationException extends NxDiException {
  /// The type that failed validation
  final Type objectType;

  /// Instance name that failed validation (if any)
  final String? instanceName;

  /// Name of the profile containing the object
  final String? profileName;

  const ValidationException(
    super.message, {
    required this.objectType,
    this.instanceName,
    this.profileName,
    super.innerException,
    super.innerStackTrace,
  });

  @override
  String toString() {
    final instanceInfo = instanceName != null
        ? ' with instance name "$instanceName"'
        : '';
    final profileInfo = profileName != null ? ' in profile "$profileName"' : '';
    return 'ValidationException: ${objectType.toString()}$instanceInfo$profileInfo failed validation. $message';
  }
}

/// Thrown when a configuration or setup operation is invalid
class ConfigurationException extends NxDiException {
  /// The configuration parameter that caused the issue
  final String? parameter;

  /// The invalid value that was provided
  final Object? invalidValue;

  const ConfigurationException(
    super.message, {
    this.parameter,
    this.invalidValue,
    super.innerException,
    super.innerStackTrace,
  });

  @override
  String toString() {
    final paramInfo = parameter != null ? ' (parameter: "$parameter")' : '';
    final valueInfo = invalidValue != null ? ' (value: "$invalidValue")' : '';
    return 'ConfigurationException$paramInfo$valueInfo: $message';
  }
}

/// Thrown when attempting to use a disposed locator or service
class DisposedObjectException extends NxDiException {
  /// The type of the disposed object
  final Type objectType;

  /// Instance name of the disposed object (if any)
  final String? instanceName;

  const DisposedObjectException(
    super.message, {
    required this.objectType,
    this.instanceName,
    super.innerException,
    super.innerStackTrace,
  });

  @override
  String toString() {
    final instanceInfo = instanceName != null
        ? ' with instance name "$instanceName"'
        : '';
    return 'DisposedObjectException: ${objectType.toString()}$instanceInfo has been disposed. $message';
  }
}

/// Thrown when an operation times out
class TimeoutException extends NxDiException {
  /// The operation that timed out
  final String operation;

  /// The timeout duration that was exceeded
  final Duration timeout;

  const TimeoutException(
    super.message, {
    required this.operation,
    required this.timeout,
    super.innerException,
    super.innerStackTrace,
  });

  @override
  String toString() {
    return 'TimeoutException: Operation "$operation" timed out after ${timeout.inMilliseconds}ms. $message';
  }
}

/// Thrown when a migration operation fails
class MigrationException extends NxDiException {
  /// The file path that caused the migration to fail
  final String? filePath;

  /// The migration step that failed
  final String? step;

  const MigrationException(
    super.message, {
    this.filePath,
    this.step,
    super.innerException,
    super.innerStackTrace,
  });

  @override
  String toString() {
    final fileInfo = filePath != null ? ' (file: "$filePath")' : '';
    final stepInfo = step != null ? ' (step: "$step")' : '';
    return 'MigrationException$fileInfo$stepInfo: $message';
  }
}

/// Extension methods for better exception handling
extension NxDiExceptionExtensions on Exception {
  /// Check if this exception is related to nx_di
  bool get isNxDiException => this is NxDiException;

  /// Get the root cause of a nested exception
  Object getRootCause() {
    if (this is NxDiException) {
      final nxException = this as NxDiException;
      if (nxException.innerException != null) {
        if (nxException.innerException is Exception) {
          return (nxException.innerException as Exception).getRootCause();
        }
        return nxException.innerException!;
      }
    }
    return this;
  }

  /// Get a chain of all nested exceptions
  List<Object> getExceptionChain() {
    final chain = <Object>[this];
    if (this is NxDiException) {
      final nxException = this as NxDiException;
      if (nxException.innerException != null) {
        if (nxException.innerException is Exception) {
          chain.addAll(
            (nxException.innerException as Exception).getExceptionChain(),
          );
        } else {
          chain.add(nxException.innerException!);
        }
      }
    }
    return chain;
  }
}
