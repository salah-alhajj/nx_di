import 'package:flutter_test/flutter_test.dart'
    hide test, group, setUp, tearDown, expect;
import 'package:nx_di/nx_di.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Profile Tests', () {
    late Profile profile;

    setUp(() {
      profile = Profile(name: 'test', priority: 0);
    });

    test('profile creation with basic properties', () {
      expect(profile.name, equals('test'));
      expect(profile.priority, equals(0));
      expect(profile.isActive, isFalse);
      expect(profile.dependsOn, isEmpty);
    });

    test('profile can register and retrieve factory services', () {
      profile.registerFactory<ServiceA>(() => ServiceA());
      expect(profile.isRegistered<ServiceA>(), isTrue);

      final service1 = profile.get<ServiceA>();
      final service2 = profile.get<ServiceA>();

      expect(service1, isA<ServiceA>());
      expect(service2, isA<ServiceA>());
      expect(service1, isNot(same(service2))); // Factory creates new instances
    });

    test('profile can register and retrieve singleton services', () {
      final serviceInstance = ServiceA();
      profile.registerSingleton<ServiceA>(serviceInstance);
      expect(profile.isRegistered<ServiceA>(), isTrue);

      final retrieved1 = profile.get<ServiceA>();
      final retrieved2 = profile.get<ServiceA>();

      expect(retrieved1, same(serviceInstance));
      expect(retrieved2, same(serviceInstance));
      expect(retrieved1, same(retrieved2)); // Singleton returns same instance
    });

    test('profile throws exception for unregistered service', () {
      expect(
        () => profile.get<ServiceA>(),
        throwsA(isA<ObjectNotFoundException>()),
      );
    });

    test('profile can be cleared', () async {
      profile.registerFactory<ServiceA>(() => ServiceA());
      expect(profile.isRegistered<ServiceA>(), isTrue);

      await profile.clear();
      expect(profile.isRegistered<ServiceA>(), isFalse);
    });
  });
}
