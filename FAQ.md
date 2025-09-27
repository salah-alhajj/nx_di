# 🙋 Frequently Asked Questions (FAQ)

## General

### Q: What is NxDI?

**A:** NxDI is a high-performance dependency injection (DI) container for Dart and Flutter. Its main goal is to provide a fast, reliable way to manage your app's services while offering an advanced multi-profile system for handling different environments (like development, testing, and production).

### Q: How is NxDI different from `get_it`?

**A:** While NxDI has a very similar API to `get_it` for core operations, it has some key differences:

1.  **Multi-Profile System:** This is the main feature of NxDI. It allows you to register different implementations of a service into named profiles (e.g., 'test', 'prod') and switch between them at runtime.
2.  **Priority-Based Resolution:** When multiple profiles are active, the service from the profile with the highest `priority` number is used.
3.  **Explicit Overrides:** You cannot accidentally override a registered service. You must explicitly use `RegistrationOptions(allowOverride: true)`.
4.  **Async Handling:** Instead of signals like `isReady()` or `allReady()`, NxDI uses an `await nx.getAsync<T>()` pattern, which internally waits for the async factory to complete.
5.  **Disposal:** Automatic cleanup requires your service to implement the `Disposable` or `AsyncDisposable` interface.

## Profiles

### Q: What are profiles for?

**A:** Profiles are for managing different sets of dependency configurations. A common use case is to have a default profile for your production services and a separate, higher-priority 'test' profile where you register mock services for your widgets tests.

```dart
// Register production service in default profile
nx.registerSingleton<ApiService>(ProdApiService());

// Register mock service in a 'test' profile
nx.createProfile(name: 'test', priority: 100);
nx.registerSingleton<ApiService>(
  MockApiService(),
  profileName: 'test',
  options: RegistrationOptions(allowOverride: true),
);

// In your app, ApiService is ProdApiService.
// In tests, after activating the 'test' profile, ApiService will be MockApiService.
```

### Q: How does profile priority work?

**A:** If you have multiple active profiles that register the same service type, the one from the profile with the **highest integer priority** will be returned by `get()`. This allows a 'test' profile with a priority of 100 to override a 'default' profile with a priority of 0.

## Usage

### Q: How do I handle services that need async initialization?

**A:** Register the service using `registerSingletonAsync` and resolve it using `getAsync`.

```dart
// Registration
nx.registerSingletonAsync<DatabaseService>(() async {
  final db = DatabaseService();
  await db.connect();
  return db;
});

// Resolution in an async function
final database = await nx.getAsync<DatabaseService>();
```

### Q: How do I unregister a service or clean everything up?

**A:** You can unregister a single service with `unregister<T>()` or clear all registered services with `reset()`. If your services implement the `Disposable` interface, their `dispose()` methods will be called automatically.

```dart
// Unregister a single service
await nx.unregister<ApiService>();

// Unregister and dispose everything
await nx.reset();
```

## Testing

### Q: How should I use NxDI in my tests?

**A:** The best practice is to create an isolated locator for each test or test group. This prevents side effects between tests.

```dart
void main() {
  group('MyWidget Tests', () {
    late NxLocator testLocator;

    setUp(() {
      // 1. Create a new instance for each test
      testLocator = NxLocator.asNewInstance();
      
      // 2. Register your mocks
      testLocator.registerSingleton<ApiService>(MockApiService());
    });

    tearDown(() async {
      // 3. Clean up afterwards
      await testLocator.reset();
    });

    test('should use the mocked service', () {
      final service = testLocator.get<ApiService>();
      expect(service, isA<MockApiService>());
    });
  });
}
```
