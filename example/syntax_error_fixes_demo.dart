// example/syntax_error_fixes_demo.dart

import '../lib/nx_di.dart';

/// Demonstration of syntax error fixes
/// This shows the correct way to handle common errors

class AircraftManagementRepo {
  String manageAircraft(String aircraftId) => 'Managing aircraft: $aircraftId';
}

class UserService {
  final String userId;
  UserService(this.userId);
  String getUser() => 'User: $userId';
}

class DatabaseService {
  final String host;
  final int port;
  DatabaseService(this.host, this.port);
  String connect() => 'Connected to $host:$port';
}

void main() {
  print('🔧 Syntax Error Fixes Demo\n');

  // Register services
  print('📝 Registering services...');
  NxLocator.instance.registerSingleton<AircraftManagementRepo>(
    AircraftManagementRepo(),
  );

  NxLocator.instance.registerFactoryParam<UserService, String>(
    (userId) => UserService(userId),
  );

  NxLocator.instance.registerFactoryParam2<DatabaseService, String, int>(
    (host, port) => DatabaseService(host, port),
  );
  print('✅ Services registered\n');

  // Fix 1: Correct assignment syntax
  print('🎯 Fix 1: Direct Assignment\n');

  print('❌ WRONG: AircraftManagementRepo repo = NxLocator.instance;');
  print(
    '   Error: _NxLocatorCallable can\'t be assigned to AircraftManagementRepo\n',
  );

  print('✅ CORRECT: Use callable syntax');

  // ✅ Method 1: Callable syntax (GetIt-style)
  AircraftManagementRepo repo1 = NxLocator.instance<AircraftManagementRepo>();
  print('   Method 1: NxLocator.instance<AircraftManagementRepo>()');
  print('   Result: ${repo1.manageAircraft("AC001")}');

  // ✅ Method 2: Property syntax
  AircraftManagementRepo repo2 = NxLocator.instance
      .get<AircraftManagementRepo>();
  print('   Method 2: NxLocator.instance.get<AircraftManagementRepo>()');
  print('   Same instance? ${identical(repo1, repo2)}');

  // ✅ Method 3: Global nx instance (recommended)
  AircraftManagementRepo repo3 = nx.get<AircraftManagementRepo>();
  print('   Method 3: nx.get<AircraftManagementRepo>()');
  print('   Same instance? ${identical(repo1, repo3)}');

  // Fix 2: Correct parameter method usage
  print('\n🎯 Fix 2: Parameter Method Usage\n');

  print('❌ WRONG: registerFactoryParam with 3 type arguments');
  print('   NxLocator.instance.registerFactoryParam<Service, String, int>()');
  print('   Error: 2 type parameters declared, but 3 type arguments given\n');

  print('✅ CORRECT: Use right method for parameter count');

  // ✅ 1 parameter - use registerFactoryParam
  print('   1 parameter: registerFactoryParam<UserService, String>()');
  final user = NxLocator.instance<UserService>(param1: 'user123');
  print('   Result: ${user.getUser()}');

  // ✅ 2 parameters - use registerFactoryParam2
  print(
    '   2 parameters: registerFactoryParam2<DatabaseService, String, int>()',
  );
  final db = NxLocator.instance<DatabaseService>(
    param1: 'localhost',
    param2: 5432,
  );
  print('   Result: ${db.connect()}');

  // Additional examples
  print('\n🌟 Additional Examples\n');

  // Named instances
  NxLocator.instance.registerSingleton<AircraftManagementRepo>(
    AircraftManagementRepo(),
    instanceName: 'backup',
  );

  final backupRepo = NxLocator.instance<AircraftManagementRepo>(
    instanceName: 'backup',
  );
  print('Named instance: ${backupRepo.manageAircraft("AC002")}');

  // Check registration
  final isRegistered = NxLocator.instance
      .isRegistered<AircraftManagementRepo>();
  print('Service registered? $isRegistered');

  print('\n✨ All syntax errors fixed!');
  print('\n📋 Quick Reference:');
  print('   • NxLocator.instance<Type>()                    // Get service');
  print(
    '   • NxLocator.instance<Type>(param1: value)      // With 1 parameter',
  );
  print(
    '   • NxLocator.instance<Type>(param1: v1, param2: v2) // With 2 parameters',
  );
  print(
    '   • NxLocator.instance<Type>(instanceName: "name") // Named instance',
  );
  print(
    '   • nx.get<Type>()                               // Preferred short syntax',
  );
}
