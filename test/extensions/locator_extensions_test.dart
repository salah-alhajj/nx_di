// test/extensions/locator_extensions_test.dart

import 'package:test/test.dart';
import 'package:nx_di/nx_di.dart';

class BookingRepo {
  String bookFlight() => 'Flight booked';
}

class UserService {
  final String userId;
  UserService(this.userId);
  String getUser() => 'User: $userId';
}

void main() {
  group('NxLocator Extensions Tests', () {
    late NxLocator testLocator;

    setUp(() {
      testLocator = NxLocator.asNewInstance();
    });

    tearDown(() async {
      await testLocator.reset();
    });

    test('call() extension provides alternative syntax', () {
      // Register service
      testLocator.registerSingleton<BookingRepo>(BookingRepo());

      // Test the alternative syntax using call()
      final booking1 = testLocator.call<BookingRepo>();
      final booking2 = testLocator.get<BookingRepo>(); // Standard syntax

      expect(booking1, isA<BookingRepo>());
      expect(booking2, isA<BookingRepo>());
      expect(identical(booking1, booking2), isTrue); // Same singleton
      expect(booking1.bookFlight(), equals('Flight booked'));
    });

    test('locator() function provides desired syntax', () {
      // Register service with global nx
      nx.registerSingleton<BookingRepo>(BookingRepo());

      // This is the closest to your desired syntax: locator<BookingRepo>()
      final booking1 = locator<BookingRepo>();
      final booking2 = nx.get<BookingRepo>(); // Standard syntax

      expect(booking1, isA<BookingRepo>());
      expect(booking2, isA<BookingRepo>());
      expect(identical(booking1, booking2), isTrue); // Same singleton
      expect(booking1.bookFlight(), equals('Flight booked'));

      // Clean up
      nx.reset();
    });

    test('locator() function works with parameters', () {
      // Register parameterized factory
      nx.registerFactoryParam<UserService, String>(
        (userId) => UserService(userId),
      );

      // Use function syntax with parameters
      final user = locator<UserService>(param1: 'user123');

      expect(user, isA<UserService>());
      expect(user.getUser(), equals('User: user123'));

      // Clean up
      nx.reset();
    });

    test('locator() function works with named instances', () {
      // Register named instances
      nx.registerSingleton<BookingRepo>(
        BookingRepo(),
        instanceName: 'domestic',
      );
      nx.registerSingleton<BookingRepo>(
        BookingRepo(),
        instanceName: 'international',
      );

      // Use function syntax with named instances
      final domestic = locator<BookingRepo>(instanceName: 'domestic');
      final international = locator<BookingRepo>(instanceName: 'international');

      expect(domestic, isA<BookingRepo>());
      expect(international, isA<BookingRepo>());
      expect(
        identical(domestic, international),
        isFalse,
      ); // Different instances

      // Clean up
      nx.reset();
    });
  });
}
