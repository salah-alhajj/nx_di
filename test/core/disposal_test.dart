import 'package:nx_di/nx_di.dart';

import '../test_helper.dart';

void main() {
  late NxLocator nx;
  late DisposableService service;

  // Before each test, create a new locator and a new service instance
  // to ensure perfect isolation between test cases.
  setUp(() {
    nx = NxLocator.asNewInstance();
    service = DisposableService();
  });

  group('Disposal Logic Tests', () {
    test(
      '1. unregister() with disposeDependency=true should call dispose',
      () async {
        // Arrange
        nx.registerSingleton<DisposableService>(service);

        // Act
        await nx.unregister<DisposableService>(disposeDependency: true);

        // Assert
        expect(
          service.isDisposed,
          isTrue,
          reason: 'Dispose method should be called on unregister.',
        );
      },
    );

    test(
      '2. unregister() with disposeDependency=false should NOT call dispose',
      () async {
        // Arrange
        nx.registerSingleton<DisposableService>(service);

        // Act
        await nx.unregister<DisposableService>(disposeDependency: false);

        // Assert
        expect(
          service.isDisposed,
          isFalse,
          reason: 'Dispose method should NOT be called when flag is false.',
        );
      },
    );

    test(
      '3. reset() with dispose=true (default) should dispose all services',
      () async {
        // Arrange
        nx.registerSingleton<DisposableService>(service);

        // Act
        await nx.reset();

        // Assert
        expect(
          service.isDisposed,
          isTrue,
          reason: 'Dispose method should be called on reset.',
        );
      },
    );

    test(
      '4. deactivateProfile() with dispose=true should dispose its services',
      () async {
        // Arrange
        nx.createProfile(name: 'disposable_profile');
        nx.registerSingleton<DisposableService>(
          service,
          profileName: 'disposable_profile',
        );
        await nx.activateProfile('disposable_profile');

        // Act
        await nx.deactivateProfile('disposable_profile', dispose: true);

        // Assert
        expect(
          service.isDisposed,
          isTrue,
          reason: 'Disposing a profile should dispose its services.',
        );
      },
    );

    test(
      '5. deactivateProfile() with dispose=false should NOT dispose its services',
      () async {
        // Arrange
        nx.createProfile(name: 'disposable_profile');
        nx.registerSingleton<DisposableService>(
          service,
          profileName: 'disposable_profile',
        );
        await nx.activateProfile('disposable_profile');

        // Act
        await nx.deactivateProfile('disposable_profile', dispose: false);

        // Assert
        expect(
          service.isDisposed,
          isFalse,
          reason:
              'Deactivating a profile without the dispose flag should not dispose services.',
        );
      },
    );
  });
}
