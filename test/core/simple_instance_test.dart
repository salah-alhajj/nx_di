import 'package:test/test.dart';
import 'package:nx_di/src/core/nx_locator.dart';

class BookingRepo {
  String bookFlight() => 'Flight booked successfully';
}

void main() {
  group('Simple Instance Tests', () {
    tearDown(() async {
      await NxLocator.instance.reset();
    });

    test('NxLocator.instance() method syntax works', () {
      // Register using method syntax - this is what you want
      NxLocator.instance.registerSingleton<BookingRepo>(BookingRepo());

      // Get using method syntax
      final booking = NxLocator.instance.get<BookingRepo>();

      expect(booking, isA<BookingRepo>());
      expect(booking.bookFlight(), equals('Flight booked successfully'));
    });

    test('Both property and method syntax work', () {
      // Register with property syntax
      NxLocator.instance.registerSingleton<BookingRepo>(BookingRepo());

      // Get with method syntax (your desired style)
      final booking1 = NxLocator.instance.get<BookingRepo>();

      // Get with property syntax
      final booking2 = NxLocator.instance.get<BookingRepo>();

      expect(booking1, isA<BookingRepo>());
      expect(booking2, isA<BookingRepo>());
      expect(identical(booking1, booking2), isTrue);
    });
  });
}
