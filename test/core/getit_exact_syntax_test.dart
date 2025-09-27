import 'package:test/test.dart';
import 'package:nx_di/src/core/nx_locator.dart';

class WithdrawalRepository {
  String processWithdrawal(double amount) =>
      'Processed withdrawal: \$${amount.toStringAsFixed(2)}';
}

class BookingRepo {
  String bookFlight() => 'Flight booked successfully';
}

void main() {
  group('GetIt Exact Syntax Tests', () {
    tearDown(() async {
      await NxLocator.instance.reset();
    });

    test(
      'NxLocator.instance<Type>() works exactly like GetIt.instance<Type>()',
      () {
        // Register services first
        NxLocator.instance.registerSingleton<WithdrawalRepository>(
          WithdrawalRepository(),
        );
        NxLocator.instance.registerLazySingleton<BookingRepo>(
          () => BookingRepo(),
        );

        // ✅ This should work exactly like GetIt.instance<Type>()
        final withdrawal = NxLocator.instance<WithdrawalRepository>();
        final booking = NxLocator.instance<BookingRepo>();

        expect(withdrawal, isA<WithdrawalRepository>());
        expect(booking, isA<BookingRepo>());
        expect(
          withdrawal.processWithdrawal(100.50),
          equals('Processed withdrawal: \$100.50'),
        );
        expect(booking.bookFlight(), equals('Flight booked successfully'));
      },
    );

    test('Both GetIt syntax patterns work', () {
      // Register services
      NxLocator.instance.registerSingleton<WithdrawalRepository>(
        WithdrawalRepository(),
      );

      // ✅ Property style: NxLocator.instance.method()
      final isRegistered = NxLocator.instance
          .isRegistered<WithdrawalRepository>();
      expect(isRegistered, isTrue);

      // ✅ Callable style: NxLocator.instance<Type>()
      final repo1 = NxLocator.instance<WithdrawalRepository>();

      // ✅ Property style get: NxLocator.instance.get<Type>()
      final repo2 = NxLocator.instance.get<WithdrawalRepository>();

      expect(repo1, isA<WithdrawalRepository>());
      expect(repo2, isA<WithdrawalRepository>());
      expect(identical(repo1, repo2), isTrue); // Same singleton instance
    });

    test('Parameters work with callable syntax', () {
      // Register parameterized factory
      NxLocator.instance.registerFactoryParam<WithdrawalRepository, double>(
        (amount) => WithdrawalRepository(),
      );

      // ✅ Should work with parameters like GetIt
      final repo = NxLocator.instance<WithdrawalRepository>(param1: 500.0);

      expect(repo, isA<WithdrawalRepository>());
      expect(
        repo.processWithdrawal(500.0),
        equals('Processed withdrawal: \$500.00'),
      );
    });

    test('Named instances work with callable syntax', () {
      // Register named instances
      NxLocator.instance.registerSingleton<WithdrawalRepository>(
        WithdrawalRepository(),
        instanceName: 'savings',
      );
      NxLocator.instance.registerSingleton<WithdrawalRepository>(
        WithdrawalRepository(),
        instanceName: 'checking',
      );

      // ✅ Should work with named instances
      final savings = NxLocator.instance<WithdrawalRepository>(
        instanceName: 'savings',
      );
      final checking = NxLocator.instance<WithdrawalRepository>(
        instanceName: 'checking',
      );

      expect(savings, isA<WithdrawalRepository>());
      expect(checking, isA<WithdrawalRepository>());
      expect(identical(savings, checking), isFalse); // Different instances
    });

    test('Registration methods work with property syntax', () {
      // ✅ All these should work like GetIt.instance.method()
      NxLocator.instance.registerSingleton<WithdrawalRepository>(
        WithdrawalRepository(),
      );
      NxLocator.instance.registerLazySingleton<BookingRepo>(
        () => BookingRepo(),
      );
      NxLocator.instance.registerFactory<String>(() => 'factory-string');

      // Verify they're all registered
      expect(NxLocator.instance.isRegistered<WithdrawalRepository>(), isTrue);
      expect(NxLocator.instance.isRegistered<BookingRepo>(), isTrue);
      expect(NxLocator.instance.isRegistered<String>(), isTrue);

      // Get them using callable syntax
      final withdrawal = NxLocator.instance<WithdrawalRepository>();
      final booking = NxLocator.instance<BookingRepo>();
      final text = NxLocator.instance<String>();

      expect(withdrawal, isA<WithdrawalRepository>());
      expect(booking, isA<BookingRepo>());
      expect(text, equals('factory-string'));
    });
  });
}
