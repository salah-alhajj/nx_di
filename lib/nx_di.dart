// lib/nx_di.dart

/// Next Generation Dependency Injection for Dart & Flutter
///
/// A modern, profile-based dependency injection container that offers
/// everything get_it provides plus advanced multi-profile capabilities.
library nx_di;

import 'src/core/nx_locator.dart';

// Core classes
export 'src/core/nx_locator.dart';
export 'src/core/registration_options.dart';
export 'src/core/nx_configuration.dart';
export 'src/core/nx_diagnostics.dart';
export 'src/core/nx_cache.dart';

// Profile system
export 'src/profiles/profile.dart';
export 'src/profiles/profile_manager.dart';

// Exception handling
export 'src/exceptions/locator_exceptions.dart';

// Type definitions
export 'src/types/factory_types.dart';
export 'src/types/disposal_types.dart';

// Migration tools
export 'src/migration/get_it_migrator.dart';
export 'src/extensions/locator_extensions.dart';

// Utilities (when implemented)
// export 'src/utils/extensions.dart';
// export 'src/utils/profile_builder.dart';
// export 'src/utils/profile_presets.dart';

// Convenience re-exports for common usage patterns
// Re-export NxLocator as the main entry point
// This allows users to write: import 'package:nx_di/nx_di.dart'; and use NxLocator directly

/// Global instance accessor for drop-in get_it replacement
///
/// Usage:
/// ```dart
/// // ignore_for_file: unused_import, undefined_identifier
/// import 'package:nx_di/nx_di.dart';
///
/// nx.registerSingleton<ApiService>(ApiService());
/// final api = nx.get<ApiService>();
/// ```
NxLocator get nx => NxLocator.instance.locator;

/// Convenience access to global instance (alternative naming)
NxLocator get di => NxLocator.instance.locator;
