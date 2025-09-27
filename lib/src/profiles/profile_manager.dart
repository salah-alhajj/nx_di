// src/profiles/profile_manager.dart

import 'profile.dart';
import 'package:nx_di/src/exceptions/locator_exceptions.dart';
import 'package:nx_di/src/types/factory_types.dart';

/// Manages multiple profiles and their lifecycle
class ProfileManager {
  /// All registered profiles
  final Map<String, Profile> _profiles = {};

  /// Currently active profile names
  final Set<String> _activeProfiles = {};

  /// Profile change listeners
  final List<ProfileChangeCallback> _changeListeners = [];

  /// Cached sorted profiles (invalidated when profiles change)
  List<Profile>? _cachedSortedProfiles;
  int _sortVersion = 0;
  int _currentSortVersion = 0;

  /// Get all registered profiles (read-only)
  Map<String, Profile> get profiles => Map.unmodifiable(_profiles);

  /// Get currently active profile names (read-only)
  Set<String> get activeProfiles => Set.unmodifiable(_activeProfiles);

  /// Get active profiles sorted by priority (highest first)
  List<Profile> get activeProfilesSorted {
    if (_cachedSortedProfiles == null || _currentSortVersion != _sortVersion) {
      _cachedSortedProfiles =
          _activeProfiles.map((name) => _profiles[name]!).toList()
            ..sort((a, b) => b.priority.compareTo(a.priority));
      _currentSortVersion = _sortVersion;
    }
    return _cachedSortedProfiles!;
  }

  /// Register a new profile
  void registerProfile(Profile profile) {
    if (_profiles.containsKey(profile.name)) {
      throw ProfileException(
        'Profile "${profile.name}" is already registered',
        profileName: profile.name,
      );
    }

    _profiles[profile.name] = profile;
    _notifyListeners(profile.name, ProfileChangeType.dependencyRegistered);
  }

  /// Activate a profile
  Future<void> activateProfile(String profileName) async {
    final profile = _profiles[profileName];
    if (profile == null) {
      throw ProfileException(
        'Profile "$profileName" is not registered',
        profileName: profileName,
      );
    }

    if (_activeProfiles.contains(profileName)) {
      return; // Already active
    }

    // Validate and auto-activate dependencies
    await _validateAndActivateDependencies(profile);

    _activeProfiles.add(profileName);
    // FIXED: Use the public setter instead of trying to access private field
    profile.isActive = true;
    _invalidateCache();

    _notifyListeners(profileName, ProfileChangeType.activated);
  }

  /// Deactivate a profile
  Future<void> deactivateProfile(
    String profileName, {
    bool dispose = true,
  }) async {
    final profile = _profiles[profileName];
    if (profile == null) {
      throw ProfileException(
        'Profile "$profileName" is not registered',
        profileName: profileName,
      );
    }

    if (!_activeProfiles.contains(profileName)) {
      return; // Already inactive
    }

    // Check if other active profiles depend on this one
    _validateProfileDeactivation(profileName);

    _activeProfiles.remove(profileName);
    // FIXED: Use the public setter instead of trying to access private field
    profile.isActive = false;
    _invalidateCache();

    if (dispose) {
      await profile.clear(dispose: true);
    }

    _notifyListeners(profileName, ProfileChangeType.deactivated);
  }

  /// Switch to a different set of profiles
  Future<void> switchToProfiles(
    Set<String> profileNames, {
    bool disposeDeactivated = true,
  }) async {
    final currentActive = Set<String>.from(_activeProfiles);
    final toActivate = profileNames.difference(currentActive);
    final toDeactivate = currentActive.difference(profileNames);

    // Validate that all profiles exist
    for (final profileName in profileNames) {
      if (!_profiles.containsKey(profileName)) {
        throw ProfileException(
          'Profile "$profileName" is not registered',
          profileName: profileName,
        );
      }
    }

    // Deactivate profiles that are no longer needed
    for (final profileName in toDeactivate) {
      await deactivateProfile(profileName, dispose: disposeDeactivated);
    }

    // Activate new profiles
    for (final profileName in toActivate) {
      await activateProfile(profileName);
    }
  }

  /// Try to resolve a dependency from active profiles
  T? tryResolve<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) {
    final sortedProfiles = activeProfilesSorted;

    for (final profile in sortedProfiles) {
      final result = profile.tryGet<T>(
        instanceName: instanceName,
        param1: param1,
        param2: param2,
      );

      if (result != null) {
        _notifyListeners(profile.name, ProfileChangeType.dependencyResolved);
        return result;
      }
    }

    return null;
  }

  /// Resolve a dependency from active profiles (throws if not found)
  T resolve<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) {
    final result = tryResolve<T>(
      instanceName: instanceName,
      param1: param1,
      param2: param2,
    );

    if (result != null) {
      return result;
    }

    throw ObjectNotFoundException(
      'Object of type ${T.toString()} was not found in any active profile',
      objectType: T,
      instanceName: instanceName,
      searchedProfiles: _activeProfiles.toList(),
    );
  }

  /// Try to resolve a dependency from active profiles asynchronously
  Future<T?> tryResolveAsync<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) async {
    final sortedProfiles = activeProfilesSorted;

    for (final profile in sortedProfiles) {
      try {
        final result = await profile.getAsync<T>(
          instanceName: instanceName,
          param1: param1,
          param2: param2,
        );
        _notifyListeners(profile.name, ProfileChangeType.dependencyResolved);
        return result;
      } catch (e) {
        // Ignore and try next profile
      }
    }

    return null;
  }

  /// Resolve a dependency from active profiles asynchronously (throws if not found)
  Future<T> resolveAsync<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) async {
    final result = await tryResolveAsync<T>(
      instanceName: instanceName,
      param1: param1,
      param2: param2,
    );

    if (result != null) {
      return result;
    }

    throw ObjectNotFoundException(
      'Object of type ${T.toString()} was not found in any active profile',
      objectType: T,
      instanceName: instanceName,
      searchedProfiles: _activeProfiles.toList(),
    );
  }

  /// Check if a type is registered in any active profile
  bool isRegistered<T extends Object>({String? instanceName}) {
    return activeProfilesSorted.any(
      (profile) => profile.isRegistered<T>(instanceName: instanceName),
    );
  }

  /// Get profile by name
  Profile? getProfile(String name) => _profiles[name];

  /// Remove a profile completely
  Future<void> removeProfile(String profileName, {bool dispose = true}) async {
    final profile = _profiles[profileName];
    if (profile == null) return;

    if (_activeProfiles.contains(profileName)) {
      await deactivateProfile(profileName, dispose: dispose);
    }

    _profiles.remove(profileName);
  }

  /// Clear all profiles
  Future<void> clearAll({bool dispose = true}) async {
    // Deactivate all profiles first
    final profilesToDeactivate = List<String>.from(_activeProfiles);
    for (final profileName in profilesToDeactivate) {
      await deactivateProfile(profileName, dispose: dispose);
    }

    // Remove all profiles
    _profiles.clear();
    _activeProfiles.clear();
    _invalidateCache();
  }

  /// Add a profile change listener
  void addChangeListener(ProfileChangeCallback listener) {
    _changeListeners.add(listener);
  }

  /// Remove a profile change listener
  bool removeChangeListener(ProfileChangeCallback listener) {
    return _changeListeners.remove(listener);
  }

  /// Get comprehensive performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final profileStats = <String, Map<String, dynamic>>{};
    int totalServices = 0;
    int totalAccesses = 0;

    for (final profile in _profiles.values) {
      final stats = profile.getPerformanceStats();
      profileStats[profile.name] = stats;
      totalServices += stats['service_count'] as int;
      totalAccesses += stats['total_accesses'] as int;
    }

    return {
      'total_profiles': _profiles.length,
      'active_profiles': _activeProfiles.length,
      'total_services': totalServices,
      'total_accesses': totalAccesses,
      'profile_stats': profileStats,
      'active_profile_names': _activeProfiles.toList(),
      'resolution_order': activeProfilesSorted.map((p) => p.name).toList(),
    };
  }

  /// Validate all active profiles and their dependencies
  Future<List<ValidationIssue>> validateProfiles() async {
    final issues = <ValidationIssue>[];

    // Check for missing profile dependencies
    for (final profileName in _activeProfiles) {
      final profile = _profiles[profileName]!;

      for (final depName in profile.dependsOn) {
        if (!_profiles.containsKey(depName)) {
          issues.add(
            ValidationIssue(
              type: ValidationIssueType.missingProfileDependency,
              message:
                  'Profile "$profileName" depends on missing profile "$depName"',
              profileName: profileName,
            ),
          );
        } else if (!_activeProfiles.contains(depName)) {
          issues.add(
            ValidationIssue(
              type: ValidationIssueType.inactiveDependency,
              message:
                  'Profile "$profileName" depends on inactive profile "$depName"',
              profileName: profileName,
            ),
          );
        }
      }
    }

    // Check for circular profile dependencies
    for (final profileName in _activeProfiles) {
      final circular = _findCircularProfileDependencies(
        profileName,
        <String>{},
      );
      if (circular.isNotEmpty) {
        issues.add(
          ValidationIssue(
            type: ValidationIssueType.circularDependency,
            message:
                'Circular profile dependency detected: ${circular.join(" -> ")}',
            profileName: profileName,
          ),
        );
      }
    }

    return issues;
  }

  // Internal methods

  Future<void> _validateAndActivateDependencies(Profile profile) async {
    // Check that all dependencies exist
    for (final depName in profile.dependsOn) {
      if (!_profiles.containsKey(depName)) {
        throw ProfileException(
          'Profile "${profile.name}" depends on "$depName" which is not registered',
          profileName: profile.name,
        );
      }
    }

    // Check for circular dependencies
    final circular = _findCircularProfileDependencies(profile.name, <String>{});
    if (circular.isNotEmpty) {
      throw CircularDependencyException(
        'Activating profile "${profile.name}" would create circular dependency',
        dependencyChain: circular
            .map((name) => _profiles[name]!.runtimeType)
            .toList(),
      );
    }

    // Auto-activate dependencies
    for (final depName in profile.dependsOn) {
      if (!_activeProfiles.contains(depName)) {
        await activateProfile(depName);
      }
    }
  }

  void _validateProfileDeactivation(String profileName) {
    final dependentProfiles = _activeProfiles.where((activeName) {
      final activeProfile = _profiles[activeName]!;
      return activeProfile.dependsOn.contains(profileName);
    }).toList();

    if (dependentProfiles.isNotEmpty) {
      throw ProfileException(
        'Cannot deactivate profile "$profileName" because it is required by: ${dependentProfiles.join(", ")}',
        profileName: profileName,
      );
    }
  }

  List<String> _findCircularProfileDependencies(
    String profileName,
    Set<String> visited,
  ) {
    if (visited.contains(profileName)) {
      return [profileName]; // Circular dependency found
    }

    final profile = _profiles[profileName];
    if (profile == null) return [];

    visited.add(profileName);

    for (final depName in profile.dependsOn) {
      final circular = _findCircularProfileDependencies(
        depName,
        Set.from(visited),
      );
      if (circular.isNotEmpty) {
        return [profileName, ...circular];
      }
    }

    return [];
  }

  void _invalidateCache() {
    _cachedSortedProfiles = null;
    _sortVersion++;
  }

  /// Internal method for synchronously activating the default profile during construction
  void activateDefaultProfileSync(String profileName) {
    final profile = _profiles[profileName];
    if (profile == null) {
      throw ProfileException(
        'Profile "$profileName" is not registered',
        profileName: profileName,
      );
    }

    if (!_activeProfiles.contains(profileName)) {
      _activeProfiles.add(profileName);
      profile.isActive = true;
      _invalidateCache();

      _notifyListeners(profileName, ProfileChangeType.activated);
    }
  }

  void _notifyListeners(String profileName, ProfileChangeType changeType) {
    for (final listener in _changeListeners) {
      try {
        listener(profileName, changeType);
      } catch (e) {
        print('Error in profile change listener: $e');
      }
    }
  }
}

/// Result of profile validation
class ValidationResult {
  final List<ValidationIssue> issues;
  final List<String> warnings;

  const ValidationResult({required this.issues, required this.warnings});

  bool get isValid => issues.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasIssues => issues.isNotEmpty;

  @override
  String toString() =>
      'ValidationResult(issues: ${issues.length}, warnings: ${warnings.length})';
}

/// A validation issue found during profile validation
class ValidationIssue {
  final ValidationIssueType type;
  final String message;
  final String? profileName;
  final Type? dependencyType;

  const ValidationIssue({
    required this.type,
    required this.message,
    this.profileName,
    this.dependencyType,
  });

  @override
  String toString() => 'ValidationIssue(${type.name}): $message';
}

/// Types of validation issues
enum ValidationIssueType {
  missingProfileDependency,
  inactiveDependency,
  circularDependency,
  missingDependency,
  multipleRegistrations,
}
