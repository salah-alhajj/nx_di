// example/multi_profile_example.dart

import 'package:nx_di/nx_di.dart';

/// Multi-Profile System Example
///
/// This example demonstrates:
/// - Creating and managing profiles
/// - Environment-based service configuration
/// - Profile activation and switching
/// - Profile dependencies

// Abstract interfaces
abstract class ApiService {
  Future<String> fetchData();
  String get baseUrl;
}

abstract class CacheService {
  void store(String key, dynamic value);
  T? get<T>(String key);
  void clear();
}

abstract class LoggerService {
  void debug(String message);
  void info(String message);
  void warning(String message);
  void error(String message);
}

// Development implementations
class DevApiService implements ApiService {
  @override
  String get baseUrl => 'http://localhost:3000';

  @override
  Future<String> fetchData() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return 'Dev data from $baseUrl';
  }
}

class DevCacheService implements CacheService {
  final Map<String, dynamic> _cache = {};

  @override
  void store(String key, dynamic value) {
    _cache[key] = value;
    print('[DEV-CACHE] Stored: $key');
  }

  @override
  T? get<T>(String key) {
    final value = _cache[key] as T?;
    print('[DEV-CACHE] Retrieved: $key -> $value');
    return value;
  }

  @override
  void clear() {
    _cache.clear();
    print('[DEV-CACHE] Cleared all entries');
  }
}

class DevLogger implements LoggerService {
  void _log(String level, String message) {
    print('[DEV-$level] ${DateTime.now()}: $message');
  }

  @override
  void debug(String message) => _log('DEBUG', message);

  @override
  void info(String message) => _log('INFO', message);

  @override
  void warning(String message) => _log('WARN', message);

  @override
  void error(String message) => _log('ERROR', message);
}

// Production implementations
class ProdApiService implements ApiService {
  @override
  String get baseUrl => 'https://api.production.com';

  @override
  Future<String> fetchData() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return 'Production data from $baseUrl';
  }
}

class ProdCacheService implements CacheService {
  final Map<String, dynamic> _cache = {};

  @override
  void store(String key, dynamic value) {
    _cache[key] = value;
    // In production, this might use Redis or similar
  }

  @override
  T? get<T>(String key) {
    return _cache[key] as T?;
  }

  @override
  void clear() {
    _cache.clear();
  }
}

class ProdLogger implements LoggerService {
  void _log(String level, String message) {
    // In production, this might use a proper logging service
    if (level != 'DEBUG') {
      print('[$level] $message');
    }
  }

  @override
  void debug(String message) => _log('DEBUG', message);

  @override
  void info(String message) => _log('INFO', message);

  @override
  void warning(String message) => _log('WARN', message);

  @override
  void error(String message) => _log('ERROR', message);
}

// Test implementations
class MockApiService implements ApiService {
  @override
  String get baseUrl => 'http://mock.test';

  @override
  Future<String> fetchData() async {
    return 'Mock data for testing';
  }
}

class MockCacheService implements CacheService {
  @override
  void store(String key, dynamic value) {
    print('[MOCK-CACHE] Would store: $key -> $value');
  }

  @override
  T? get<T>(String key) {
    print('[MOCK-CACHE] Would retrieve: $key');
    return null;
  }

  @override
  void clear() {
    print('[MOCK-CACHE] Would clear cache');
  }
}

// Application service that uses the dependencies
class DataManager {
  final ApiService _api;
  final CacheService _cache;
  final LoggerService _logger;

  DataManager(this._api, this._cache, this._logger);

  Future<String> getData(String key) async {
    _logger.debug('Getting data for key: $key');

    // Try cache first
    final cached = _cache.get<String>(key);
    if (cached != null) {
      _logger.info('Cache hit for key: $key');
      return cached;
    }

    // Fetch from API
    _logger.info('Cache miss, fetching from API: ${_api.baseUrl}');
    final data = await _api.fetchData();

    // Store in cache
    _cache.store(key, data);
    _logger.info('Data fetched and cached for key: $key');

    return data;
  }
}

void setupProfiles() {
  print('🏗️ Setting up profiles...\n');

  // Create base profile for common services
  nx.createProfile(name: 'base', priority: 50);
  print('✅ Created "base" profile (priority: 50)');

  // Create environment profiles that depend on base
  nx.createProfile(name: 'development', priority: 100, dependsOn: ['base']);
  print('✅ Created "development" profile (priority: 100, depends on: base)');

  nx.createProfile(name: 'production', priority: 200, dependsOn: ['base']);
  print('✅ Created "production" profile (priority: 200, depends on: base)');

  nx.createProfile(name: 'testing', priority: 150, dependsOn: ['base']);
  print('✅ Created "testing" profile (priority: 150, depends on: base)');

  print('');
}

void registerBaseServices() {
  print('📦 Registering base services...\n');

  // Register DataManager factory in base profile
  nx.registerFactory<DataManager>(() {
    final api = nx.get<ApiService>();
    final cache = nx.get<CacheService>();
    final logger = nx.get<LoggerService>();
    return DataManager(api, cache, logger);
  }, profileName: 'base');
  print('✅ Registered DataManager factory in "base" profile');

  print('');
}

void registerDevelopmentServices() {
  print('🛠️ Registering development services...\n');

  nx.registerSingleton<ApiService>(DevApiService(), profileName: 'development');
  print('✅ Registered DevApiService in "development" profile');

  nx.registerSingleton<CacheService>(
    DevCacheService(),
    profileName: 'development',
  );
  print('✅ Registered DevCacheService in "development" profile');

  nx.registerSingleton<LoggerService>(DevLogger(), profileName: 'development');
  print('✅ Registered DevLogger in "development" profile');

  print('');
}

void registerProductionServices() {
  print('🚀 Registering production services...\n');

  nx.registerSingleton<ApiService>(ProdApiService(), profileName: 'production');
  print('✅ Registered ProdApiService in "production" profile');

  nx.registerLazySingleton<CacheService>(
    () => ProdCacheService(),
    profileName: 'production',
  );
  print('✅ Registered ProdCacheService in "production" profile');

  nx.registerSingleton<LoggerService>(ProdLogger(), profileName: 'production');
  print('✅ Registered ProdLogger in "production" profile');

  print('');
}

void registerTestingServices() {
  print('🧪 Registering testing services...\n');

  nx.registerSingleton<ApiService>(MockApiService(), profileName: 'testing');
  print('✅ Registered MockApiService in "testing" profile');

  nx.registerSingleton<CacheService>(
    MockCacheService(),
    profileName: 'testing',
  );
  print('✅ Registered MockCacheService in "testing" profile');

  nx.registerSingleton<LoggerService>(
    DevLogger(), // Use dev logger for tests
    profileName: 'testing',
  );
  print('✅ Registered DevLogger in "testing" profile');

  print('');
}

Future<void> demonstrateEnvironment(String environment) async {
  print('🌍 Demonstrating "$environment" environment...\n');

  // Activate the environment profile
  nx.activateProfile(environment);
  print('✅ Activated "$environment" profile');

  // Check which profiles are active
  final activeProfiles = nx.profiles.activeProfiles;
  print('📋 Active profiles: ${activeProfiles.join(', ')}');

  // Get services (they'll be resolved from the active environment)
  final dataManager = nx.get<DataManager>();
  final logger = nx.get<LoggerService>();

  logger.info('Running in $environment environment');

  // Use the data manager
  try {
    final data1 = await dataManager.getData('user_123');
    logger.info('First fetch result: $data1');

    final data2 = await dataManager.getData('user_123');
    logger.info('Second fetch result (should be cached): $data2');
  } catch (e) {
    logger.error('Error fetching data: $e');
  }

  print('');
}

void main() async {
  print('🎭 NxDI Multi-Profile System Example\n');
  print('=' * 50);

  // Setup all profiles and services
  setupProfiles();
  registerBaseServices();
  registerDevelopmentServices();
  registerProductionServices();
  registerTestingServices();

  print('🎬 Starting environment demonstrations...\n');
  print('=' * 50);

  // Demonstrate each environment
  await demonstrateEnvironment('development');
  print('-' * 30);

  await demonstrateEnvironment('production');
  print('-' * 30);

  await demonstrateEnvironment('testing');
  print('-' * 30);

  // Demonstrate profile switching
  print('🔄 Demonstrating profile switching...\n');

  print('Switching back to development...');
  nx.activateProfile('development');
  final logger = nx.get<LoggerService>();
  logger.info('Back in development mode!');

  print('\nSwitching to production...');
  nx.activateProfile('production');
  final prodLogger = nx.get<LoggerService>();
  prodLogger.info('Now in production mode!');

  // Show profile information
  print('\n📊 Profile Information:');
  final profiles = nx.profiles.profiles.values;
  for (final profile in profiles) {
    final isActive = nx.profiles.activeProfiles.contains(profile.name);
    final status = isActive ? '🟢 ACTIVE' : '⚪ INACTIVE';
    print('  ${profile.name} (priority: ${profile.priority}) $status');
    if (profile.dependsOn.isNotEmpty) {
      print('    Dependencies: ${profile.dependsOn.join(', ')}');
    }
  }

  print('\n✨ Multi-profile example completed!');
}
