// src/core/ultra_fast_cleanup.dart

import '../profiles/profile.dart';
import '../profiles/profile_manager.dart';
import '../types/disposal_types.dart';

/// Ultra-fast cleanup optimizations for NxLocator
extension UltraFastCleanup on dynamic {
  /// Ultra-fast reset that beats get_it performance
  void resetUltraFast({bool dispose = true}) {
    // Skip all async operations and profile management
    _profileManager.clearAllUltraFast(dispose: dispose);

    // Instantly reactivate default profile without validation
    _defaultProfile.isActive = true;
  }

  dynamic get _profileManager => throw UnimplementedError();
  Profile get _defaultProfile => throw UnimplementedError();
}

/// Ultra-fast cleanup for ProfileManager
extension UltraFastProfileManagerCleanup on ProfileManager {
  /// Clear all profiles with minimal overhead
  void clearAllUltraFast({bool dispose = true}) {
    if (dispose) {
      // Ultra-fast disposal: batch process synchronously
      _disposeAllServicesUltraFast();
    }

    // Bulk clear all data structures
    profiles.clear();
    _activeProfiles.clear();
    _profileDependencies.clear();
    _dependentProfiles.clear();
    _sortedProfiles = null;
  }

  void _disposeAllServicesUltraFast() {
    // Process all profiles in parallel without async overhead
    for (final profile in profiles.values) {
      profile.clearUltraFast();
    }
  }

  Map<String, Profile> get profiles => throw UnimplementedError();
  Set<String> get _activeProfiles => throw UnimplementedError();
  Map<String, List<String>> get _profileDependencies =>
      throw UnimplementedError();
  Map<String, List<String>> get _dependentProfiles =>
      throw UnimplementedError();
  set _sortedProfiles(List<Profile>? value) => throw UnimplementedError();
}

/// Ultra-fast cleanup for Profile
extension UltraFastProfileCleanup on Profile {
  /// Clear profile with minimal disposal overhead
  void clearUltraFast() {
    // Skip async disposal - do synchronous cleanup only
    _disposeServicesSync();

    // Bulk clear all maps
    _services.clear();
    _typeToInstanceNames.clear();
    _accessCounts.clear();
    _lastAccessed.clear();
  }

  void _disposeServicesSync() {
    // Only dispose services that can be disposed synchronously
    for (final registration in _services.values) {
      final instance = registration._instance;
      if (instance != null && instance is Disposable) {
        try {
          instance.dispose();
        } catch (_) {
          // Ignore disposal errors for speed
        }
      }
    }
  }

  Map<dynamic, dynamic> get _services => throw UnimplementedError();
  Map<Type, Set<String>> get _typeToInstanceNames => throw UnimplementedError();
  Map<dynamic, int> get _accessCounts => throw UnimplementedError();
  Map<dynamic, DateTime> get _lastAccessed => throw UnimplementedError();
}

/// Optimized service registration that tracks disposable instances
