import 'package:flutter_test/flutter_test.dart'
    hide test, group, setUp, tearDown, expect;
import 'package:test/test.dart';
import 'package:nx_di/src/core/nx_locator.dart';

class BookingRepo {
  String bookFlight() => 'Flight booked successfully';
}

class RangeAvailabilityRepository {
  List<String> getAvailableRanges() => ['Range A', 'Range B', 'Range C'];
}

class UserService {
  final String userId;
  UserService(this.userId);
  String getUser() => 'User: $userId';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('GetIt Compatibility Tests', () {
    tearDown(() async {
      await NxLocator.instance.reset();
    });

    test('NxLocator.instance() works exactly like GetIt.instance()', () {
      // Register services using the method syntax (like get_it)
      NxLocator.instance.registerSingleton<BookingRepo>(BookingRepo());
      NxLocator.instance.registerLazySingleton<RangeAvailabilityRepository>(
        () => RangeAvailabilityRepository(),
      );

      // Get services using the method syntax
      final bookingRepo = NxLocator.instance.get<BookingRepo>();
      final rangeRepo = NxLocator.instance.get<RangeAvailabilityRepository>();

      expect(bookingRepo, isA<BookingRepo>());
      expect(rangeRepo, isA<RangeAvailabilityRepository>());
      expect(bookingRepo.bookFlight(), equals('Flight booked successfully'));
      expect(
        rangeRepo.getAvailableRanges(),
        equals(['Range A', 'Range B', 'Range C']),
      );
    });

    test('Can mix property and method syntax', () {
      // Register with property syntax
      NxLocator.instance.registerSingleton<BookingRepo>(BookingRepo());

      // Get with method syntax
      final booking1 = NxLocator.instance.get<BookingRepo>();

      // Register with method syntax
      NxLocator.instance.registerLazySingleton<RangeAvailabilityRepository>(
        () => RangeAvailabilityRepository(),
      );

      // Get with property syntax
      final range1 = NxLocator.instance.get<RangeAvailabilityRepository>();

      expect(booking1, isA<BookingRepo>());
      expect(range1, isA<RangeAvailabilityRepository>());
    });

    test('Method chaining works like get_it', () {
      // Chain multiple operations
      NxLocator.instance
          .registerSingleton<BookingRepo>(BookingRepo())
          .registerLazySingleton<RangeAvailabilityRepository>(
            () => RangeAvailabilityRepository(),
          )
          .registerFactory<UserService>(() => UserService('default-user'));

      // Verify all services are registered
      expect(NxLocator.instance.isRegistered<BookingRepo>(), isTrue);
      expect(
        NxLocator.instance.isRegistered<RangeAvailabilityRepository>(),
        isTrue,
      );
      expect(NxLocator.instance.isRegistered<UserService>(), isTrue);

      // Get services
      final booking = NxLocator.instance.get<BookingRepo>();
      final range = NxLocator.instance.get<RangeAvailabilityRepository>();
      final user = NxLocator.instance.get<UserService>();

      expect(booking.bookFlight(), equals('Flight booked successfully'));
      expect(range.getAvailableRanges().length, equals(3));
      expect(user.getUser(), equals('User: default-user'));
    });

    test('supports all registration methods with method syntax', () {
      final locator = NxLocator.instance;

      // Test basic registration methods
      locator.registerSingleton<BookingRepo>(BookingRepo());
      locator.registerLazySingleton<RangeAvailabilityRepository>(
        () => RangeAvailabilityRepository(),
      );
      locator.registerFactory<UserService>(() => UserService('factory-user'));

      // Verify all work
      expect(locator.get<BookingRepo>(), isA<BookingRepo>());
      expect(
        locator.get<RangeAvailabilityRepository>(),
        isA<RangeAvailabilityRepository>(),
      );
      expect(locator.get<UserService>(), isA<UserService>());
    });
  });
}
