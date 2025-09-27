// example/basic_usage.dart

import 'package:nx_di/nx_di.dart';

/// Basic NxDI usage example
///
/// This example demonstrates:
/// - Service registration
/// - Service retrieval
/// - Different registration types
/// - Basic error handling

// Example services
class Logger {
  void info(String message) => print('[INFO] $message');
  void error(String message) => print('[ERROR] $message');
}

class DatabaseService {
  bool _connected = false;

  void connect() {
    _connected = true;
    print('Database connected');
  }

  void disconnect() {
    _connected = false;
    print('Database disconnected');
  }

  bool get isConnected => _connected;
}

class UserService {
  final Logger _logger;
  final DatabaseService _database;

  UserService(this._logger, this._database);

  void createUser(String name) {
    if (!_database.isConnected) {
      _database.connect();
    }
    _logger.info('Creating user: $name');
    // Simulate user creation
    print('User "$name" created successfully');
  }
}

void main() {
  print('🚀 NxDI Basic Usage Example\n');

  // Register services

  // 1. Singleton: Same instance returned every time
  nx.registerSingleton<Logger>(Logger());
  print('✅ Registered Logger as singleton');

  // 2. Lazy Singleton: Created only when first accessed
  nx.registerLazySingleton<DatabaseService>(() {
    print('🔄 Creating DatabaseService instance...');
    return DatabaseService();
  });
  print('✅ Registered DatabaseService as lazy singleton');

  // 3. Factory: New instance created every time
  nx.registerFactory<UserService>(() {
    final logger = nx.get<Logger>();
    final database = nx.get<DatabaseService>();
    return UserService(logger, database);
  });
  print('✅ Registered UserService as factory\n');

  // Use services

  print('📖 Getting services...');

  // Get logger (singleton - always same instance)
  final logger1 = nx.get<Logger>();
  final logger2 = nx.get<Logger>();
  print('Logger instances identical: ${identical(logger1, logger2)}');

  // Get database (lazy singleton - created on first access)
  print('\n🗄️ Accessing database for first time:');
  final database1 = nx.get<DatabaseService>();
  print('🗄️ Accessing database again:');
  final database2 = nx.get<DatabaseService>();
  print('Database instances identical: ${identical(database1, database2)}');

  // Get user service (factory - new instance each time)
  print('\n👤 Getting user services:');
  final userService1 = nx.get<UserService>();
  final userService2 = nx.get<UserService>();
  print(
    'UserService instances identical: ${identical(userService1, userService2)}',
  );

  // Use the services
  print('\n🎬 Using services:');
  userService1.createUser('Alice');
  userService2.createUser('Bob');

  // Check registration status
  print('\n🔍 Checking service registration:');
  print('Logger registered: ${nx.isRegistered<Logger>()}');
  print('DatabaseService registered: ${nx.isRegistered<DatabaseService>()}');
  print('UserService registered: ${nx.isRegistered<UserService>()}');
  print(
    'NonExistentService registered: ${nx.isRegistered<NonExistentService>()}',
  );

  // Safe service retrieval
  print('\n🛡️ Safe service retrieval:');
  final safeLogger = nx.tryGet<Logger>();
  print('Safe logger retrieval: ${safeLogger != null ? "Success" : "Failed"}');

  final safeNonExistent = nx.tryGet<NonExistentService>();
  print(
    'Safe non-existent retrieval: ${safeNonExistent != null ? "Success" : "Failed"}',
  );

  // Error handling
  print('\n❌ Error handling example:');
  try {
    final nonExistent = nx.get<NonExistentService>();
    print('This should not print: $nonExistent');
  } catch (e) {
    print('Caught expected error: ${e.runtimeType}');
    print('Error message: $e');
  }

  print('\n✨ Basic usage example completed!');
}

class NonExistentService {}
