// example/syntax_guide.dart

import 'package:nx_di/nx_di.dart';

/// Syntax Guide Example
///
/// This example demonstrates:
/// - Correct service resolution syntax
/// - Common syntax mistakes to avoid
/// - Proper usage patterns

// Example services
class SearchRepo {
  String search(String query) => 'Results for: $query';
}

class UserService {
  final String userId;
  final int level;

  UserService(this.userId, this.level);

  String getInfo() => 'User: $userId (Level: $level)';
}

class ApiService {
  void makeRequest() => print('Making API request...');
}

void main() {
  print('🔧 NxDI Syntax Guide\n');

  // Register some services
  nx.registerSingleton<SearchRepo>(SearchRepo());
  nx.registerSingleton<ApiService>(ApiService());
  nx.registerFactoryParam2<UserService, String, int>(
    (userId, level) => UserService(userId, level),
  );

  print('✅ Services registered successfully\n');

  // CORRECT SYNTAX EXAMPLES
  print('🎯 CORRECT Usage Examples:');

  // ✅ Standard service resolution
  print('\n1. Standard service resolution:');
  final searchRepo = nx.get<SearchRepo>();
  print('✅ nx.get<SearchRepo>() - ${searchRepo.search("test")}');

  // ✅ Using NxLocator.instance (equivalent to nx)
  print('\n2. Using NxLocator.instance:');
  final apiService = NxLocator.instance.get<ApiService>();
  print('✅ NxLocator.instance.get<ApiService>() - Service resolved');
  apiService.makeRequest();

  // ✅ Parameterized service resolution
  print('\n3. Parameterized factories:');
  final userService = nx.get<UserService>(param1: 'user123', param2: 5);
  print('✅ nx.get<UserService>(param1: "user123", param2: 5)');
  print('   Result: ${userService.getInfo()}');

  // ✅ Safe service resolution
  print('\n4. Safe service resolution:');
  final safeRepo = nx.tryGet<SearchRepo>();
  print(
    '✅ nx.tryGet<SearchRepo>() - ${safeRepo != null ? "Found" : "Not found"}',
  );

  // ✅ Checking registration
  print('\n5. Checking registration:');
  final isRegistered = nx.isRegistered<SearchRepo>();
  print('✅ nx.isRegistered<SearchRepo>() - $isRegistered');

  // COMMON MISTAKES TO AVOID
  print('\n\n❌ COMMON MISTAKES TO AVOID:');

  print('\n1. ❌ WRONG: NxLocator.instance<SearchRepo>()');
  print('   Error: The expression doesn\'t evaluate to a function');
  print('   ✅ CORRECT: NxLocator.instance.get<SearchRepo>()');

  print('\n2. ❌ WRONG: nx<SearchRepo>()');
  print('   Error: nx is an instance, not a generic function');
  print('   ✅ CORRECT: nx.get<SearchRepo>()');

  print('\n3. ❌ WRONG: nx.get<SearchRepo>(SearchRepo())');
  print('   Error: get() doesn\'t take instance parameters');
  print(
    '   ✅ CORRECT: nx.registerSingleton<SearchRepo>(SearchRepo()); nx.get<SearchRepo>()',
  );

  print('\n4. ❌ WRONG: await nx.get<SearchRepo>()');
  print('   Error: get() is synchronous');
  print(
    '   ✅ CORRECT: nx.get<SearchRepo>() or await nx.getAsync<SearchRepo>()',
  );

  // BEST PRACTICES
  print('\n\n🌟 BEST PRACTICES:');

  print('\n1. Use the global nx instance for cleaner code:');
  print('   ✅ final service = nx.get<Service>();');
  print('   instead of NxLocator.instance.get<Service>();');

  print('\n2. Use tryGet() when service might not exist:');
  print('   ✅ final service = nx.tryGet<OptionalService>();');
  print('   ✅ if (service != null) { /* use service */ }');

  print('\n3. Check registration before resolving critical services:');
  print('   ✅ if (nx.isRegistered<CriticalService>()) {');
  print('       final service = nx.get<CriticalService>();');
  print('   }');

  print('\n4. Use parameterized factories for dynamic services:');
  print(
    '   ✅ nx.registerFactoryParam<UserService, String>((id) => UserService(id));',
  );
  print('   ✅ final user = nx.get<UserService>(param1: "user123");');

  print('\n\n✨ Syntax guide completed!');
  print('Remember: Always use .get<Type>() for service resolution!');
}
