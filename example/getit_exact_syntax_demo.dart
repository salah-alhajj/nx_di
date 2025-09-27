// example/getit_exact_syntax_demo.dart

import '../lib/nx_di.dart';

/// Demonstration of GetIt.instance<Type>() exact syntax compatibility
///
/// This shows that NxDI now supports both:
/// 1. NxLocator.instance<Type>() - EXACTLY like GetIt.instance<Type>()
/// 2. NxLocator.instance.method() - Property access style

class WithdrawalRepository {
  String processWithdrawal(double amount) =>
      'Processed: \$${amount.toStringAsFixed(2)}';
}

class BookingRepo {
  String bookFlight() => 'Flight booked!';
}

class UserService {
  final String userId;
  UserService(this.userId);
  String getUser() => 'User: $userId';
}

void main() {
  print('🎯 NxDI GetIt.instance<Type>() Syntax Demo\n');

  // First, register some services using property syntax
  print('📝 Registering services...');
  NxLocator.instance.registerSingleton<WithdrawalRepository>(
    WithdrawalRepository(),
  );
  NxLocator.instance.registerLazySingleton<BookingRepo>(() => BookingRepo());
  NxLocator.instance.registerFactoryParam<UserService, String>(
    (userId) => UserService(userId),
  );
  print('✅ Services registered\n');

  // Now demonstrate the EXACT GetIt syntax you wanted
  print('🚀 Using GetIt.instance<Type>() syntax:\n');

  // ✅ This is EXACTLY what you wanted: NxLocator.instance<Type>()
  print('1. Getting WithdrawalRepository:');
  final withdrawal = NxLocator.instance<WithdrawalRepository>();
  print('   Result: ${withdrawal.processWithdrawal(250.75)}');

  print('\n2. Getting BookingRepo:');
  final booking = NxLocator.instance<BookingRepo>();
  print('   Result: ${booking.bookFlight()}');

  print('\n3. Getting UserService with parameter:');
  final user = NxLocator.instance<UserService>(param1: 'user123');
  print('   Result: ${user.getUser()}');

  // Show that property syntax still works too
  print('\n📋 Property syntax also works:\n');

  print('4. Using NxLocator.instance.get<Type>():');
  final withdrawal2 = NxLocator.instance.get<WithdrawalRepository>();
  print('   Same instance? ${identical(withdrawal, withdrawal2)}');

  print('\n5. Checking registration with property syntax:');
  final isRegistered = NxLocator.instance.isRegistered<WithdrawalRepository>();
  print('   WithdrawalRepository registered? $isRegistered');

  // Demonstrate named instances
  print('\n🏷️ Named instances with callable syntax:\n');

  // Register named instances
  NxLocator.instance.registerSingleton<WithdrawalRepository>(
    WithdrawalRepository(),
    instanceName: 'savings',
  );
  NxLocator.instance.registerSingleton<WithdrawalRepository>(
    WithdrawalRepository(),
    instanceName: 'checking',
  );

  print('6. Getting named instances:');
  final savings = NxLocator.instance<WithdrawalRepository>(
    instanceName: 'savings',
  );
  final checking = NxLocator.instance<WithdrawalRepository>(
    instanceName: 'checking',
  );
  print('   Savings: ${savings.processWithdrawal(100)}');
  print('   Checking: ${checking.processWithdrawal(200)}');
  print('   Different instances? ${!identical(savings, checking)}');

  print('\n✨ Perfect GetIt compatibility achieved!');
  print('\n💡 Summary of working syntax:');
  print(
    '   ✅ NxLocator.instance<WithdrawalRepository>()           // EXACTLY like GetIt!',
  );
  print(
    '   ✅ NxLocator.instance<UserService>(param1: "value")     // With parameters',
  );
  print(
    '   ✅ NxLocator.instance<Type>(instanceName: "name")       // Named instances',
  );
  print(
    '   ✅ NxLocator.instance.registerSingleton<Type>(...)     // Property style',
  );
  print(
    '   ✅ NxLocator.instance.isRegistered<Type>()             // Property checks',
  );
}
