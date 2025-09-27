# 🚀 NxDI: The Complete Guide to Next-Generation Dependency Injection

[![Pub Version](https://img.shields.io/pub/v/nx_di)](https://pub.dev/packages/nx_di)
[![Dart SDK Version](https://badgen.net/pub/sdk-version/nx_di)](https://pub.dev/packages/nx_di)
[![License](https://img.shields.io/github/license/salah-alhajj/nx_di)](https://github.com/salah-alhajj/nx_di/blob/main/LICENSE)

**Welcome to the official guide for NxDI, a high-performance, profile-based dependency injection container for Dart and Flutter. This document covers every feature of the library, from basic usage to advanced enterprise patterns.**

---

## 📖 Table of Contents

- [🚀 NxDI: The Complete Guide to Next-Generation Dependency Injection](#-nxdi-the-complete-guide-to-next-generation-dependency-injection)
  - [📖 Table of Contents](#-table-of-contents)
  - [📜 Introduction](#-introduction)
    - [What is NxDI?](#what-is-nxdi)
    - [Core Pillars](#core-pillars)
  - [🚀 Getting Started](#-getting-started)
    - [Installation](#installation)
    - [Creating the Locator](#creating-the-locator)
  - [📦 Core Concepts: Registration \& Resolution](#-core-concepts-registration--resolution)
    - [Service Lifecycles](#service-lifecycles)
      - [1. Singleton](#1-singleton)
      - [2. Lazy Singleton](#2-lazy-singleton)
      - [3. Factory](#3-factory)
    - [Resolving Services](#resolving-services)
    - [Named Instances](#named-instances)
  - [🎭 The Multi-Profile System (A Deep Dive)](#-the-multi-profile-system-a-deep-dive)
    - [What Are Profiles?](#what-are-profiles)
    - [Creating and Managing Profiles](#creating-and-managing-profiles)
    - [Priority Explained: How Overrides Work](#priority-explained-how-overrides-work)
    - [Profile Dependencies (`dependsOn`)](#profile-dependencies-dependson)
  - [🛠️ Advanced Registration Techniques](#️-advanced-registration-techniques)
    - [Asynchronous Services](#asynchronous-services)
    - [Parameterized Factories](#parameterized-factories)
    - [Using `RegistrationOptions`](#using-registrationoptions)
  - [🗑️ Memory Management \& Disposal](#️-memory-management--disposal)
    - [The `Disposable` Interfaces](#the-disposable-interfaces)
    - [Manual Cleanup: `reset` and `unregister`](#manual-cleanup-reset-and-unregister)
  - [🧪 Testing with NxDI](#-testing-with-nxdi)
    - [The Golden Rule: Isolate Your Locator](#the-golden-rule-isolate-your-locator)
    - [A Robust Testing Pattern](#a-robust-testing-pattern)
    - [Using Profiles for Advanced Testing](#using-profiles-for-advanced-testing)
  - [📚 Full API Reference](#-full-api-reference)
    - [Locator Methods](#locator-methods)
    - [RegistrationOptions](#registrationoptions)
  - [🚑 Troubleshooting](#-troubleshooting)
    - [Common Errors](#common-errors)
    - [Common Pitfalls](#common-pitfalls)

---

## 📜 Introduction

### What is NxDI?

NxDI is a dependency injection (DI) container designed for modern Dart and Flutter applications. Dependency injection is a design pattern that allows you to "inject" dependencies (like an `ApiService` or `UserRepository`) into your classes rather than having them create their dependencies themselves. This leads to more modular, testable, and maintainable code.

NxDI provides a powerful and intuitive API to manage your application's dependencies, but its standout feature is the **multi-profile system**, which allows you to define and switch between different sets of dependency configurations at runtime.

### Core Pillars

1.  **Performance:** Built from the ground up with performance in mind, using optimized lookups and efficient memory management to ensure minimal overhead in your application.
2.  **Powerful Profile System:** Go beyond basic DI with the ability to manage separate configurations for development, testing, production, or even different feature sets within the same app.
3.  **Developer Experience:** A clean, predictable, and well-documented API that feels familiar to users of other popular DI libraries, making it easy to get started.

## 🚀 Getting Started

### Installation

Add NxDI to your project's `pubspec.yaml` file:

```yaml
dependencies:
  nx_di: ^0.7.5
```

Then, run `dart pub get` or `flutter pub get`.

### Creating the Locator

The `NxLocator` is the heart of the library. It's the container that holds all your service registrations. You have two main ways to use it:

1.  **Create a Local Instance (Recommended):** This is the best practice for most applications as it makes your dependencies explicit.

    ```dart
    // lib/service_locator.dart
    import 'package:nx_di/nx_di.dart';

    final nx = NxLocator.asNewInstance();

    void setupLocator() {
      // Register your services here
    }
    ```

2.  **Use the Global Singleton:** For quick access or compatibility with the `get_it` static style, a global instance is available.

    ```dart
    import 'package:nx_di/nx_di.dart';

    // You can access NxLocator.instance anywhere in your app.
    NxLocator.instance.registerSingleton(MyService());
    ```

For the rest of this guide, we will use a local `nx` instance.

## 📦 Core Concepts: Registration & Resolution

### Service Lifecycles

NxDI offers three ways to register a service, each defining a different lifecycle for the object it provides.

#### 1. Singleton

A singleton is an object that is created **once** and shared throughout your application. `registerSingleton` is "eager," meaning the instance is created the moment you register it.

-   **Use Case:** For services that are expensive to create, need to maintain a shared state, and are required as soon as the app starts (e.g., `DatabaseService`, `SharedPreferencesService`).

```dart
// The ApiService instance is created immediately.
nx.registerSingleton<ApiService>(ApiService());

// Every time you call get<ApiService>, you get the exact same instance.
final api1 = nx.get<ApiService>();
final api2 = nx.get<ApiService>();
print(identical(api1, api2)); // true
```

#### 2. Lazy Singleton

A lazy singleton is also created only **once**, but not until the **first time it is requested**. This is useful for optimizing your app's startup time.

-   **Use Case:** For services that are expensive but might not be needed immediately upon app launch (e.g., a `HeavyComputationService` used in a specific feature).

```dart
print('Registering lazy singleton...');
nx.registerLazySingleton<HeavyService>(() {
  print('...HeavyService is being created!');
  return HeavyService();
});

print('App is running...');
// Nothing is printed yet.

final service = nx.get<HeavyService>(); // "...HeavyService is being created!" is printed here.
final sameService = nx.get<HeavyService>(); // Nothing is printed, the cached instance is returned.
```

#### 3. Factory

A factory creates a **new instance** of a service every single time it's requested.

-   **Use Case:** For objects that need to be new and unique each time, often for stateful widgets or view models where you don't want to share state (e.g., a `ViewModel` for a specific screen).

```dart
nx.registerFactory<LoginViewModel>(() => LoginViewModel());

final viewModel1 = nx.get<LoginViewModel>();
final viewModel2 = nx.get<LoginViewModel>();
print(identical(viewModel1, viewModel2)); // false
```

### Resolving Services

Once your services are registered, you can access them from anywhere you have access to your locator instance.

-   `get<T>()`: The standard way to get a service. It throws an `ObjectNotFoundException` if the service isn't registered.
-   `tryGet<T>()`: A safe way to get a service. It returns `null` if the service isn't found, instead of throwing an exception.
-   `getAsync<T>()`: Used to resolve services that were registered asynchronously. See the [Asynchronous Services](#asynchronous-services) section.

```dart
// Standard retrieval
final apiService = nx.get<ApiService>();

// Safe retrieval
final analyticsService = nx.tryGet<AnalyticsService>();
if (analyticsService != null) {
  analyticsService.trackEvent('user_landed_on_screen');
}
```

### Named Instances

You can register multiple services of the same type by giving them a unique `instanceName`.

```dart
// Register two different configurations for ApiService
nx.registerSingleton<ApiService>(ApiService('https://api.flyme.com'), instanceName: 'prod');
nx.registerSingleton<ApiService>(ApiService('http://localhost:3000'), instanceName: 'dev');

// Resolve the specific instance you need
final prodApi = nx.get<ApiService>(instanceName: 'prod');
```

## 🎭 The Multi-Profile System (A Deep Dive)

This is the most powerful feature of NxDI. It allows you to create, manage, and switch between different sets of service registrations.

### What Are Profiles?

A profile is a named container for a set of service registrations. You can have a profile for `development`, `testing`, and `production`, each with different implementations of your services.

-   **Example:** In the `development` profile, your `ApiService` might be a mock that returns fake data. In the `production` profile, it would be the real `HttpApiService` that makes network calls.

### Creating and Managing Profiles

You can create and manage profiles with a simple API.

```dart
// 1. Create profiles
nx.createProfile(name: 'prod', priority: 100);
nx.createProfile(name: 'dev', priority: 200);

// 2. Register services to specific profiles
nx.registerSingleton<ApiService>(ProdApiService(), profileName: 'prod');
nx.registerSingleton<ApiService>(DevApiService(), profileName: 'dev');

// 3. Activate the profile you want to use
await nx.activateProfile('dev');

// Now, get<ApiService> will return the DevApiService because 'dev' is active.
final api = nx.get<ApiService>(); // Returns DevApiService

// You can switch to another set of profiles
await nx.switchToProfiles({'prod'});
final prodApi = nx.get<ApiService>(); // Returns ProdApiService
```

### Priority Explained: How Overrides Work

When you have multiple **active** profiles, the `priority` number determines which one "wins" if they both register a service of the same type. **The profile with the higher priority number takes precedence.**

This is incredibly useful for overriding base configurations.

```dart
// A base profile with a low priority
nx.createProfile(name: 'base', priority: 0);
nx.registerSingleton<ConfigService>(ConfigService.fromEnv(), profileName: 'base');

// A test profile with a higher priority
nx.createProfile(name: 'test', priority: 100);
nx.registerSingleton<ConfigService>(
  ConfigService.mock(),
  profileName: 'test',
  // You must explicitly allow overriding a service from another profile
  options: RegistrationOptions(allowOverride: true),
);

// Activate both profiles
await nx.activateProfile('base');
await nx.activateProfile('test');

// Because 'test' has a higher priority (100 > 0), it wins.
final config = nx.get<ConfigService>(); // Returns the Mock ConfigService
```

### Profile Dependencies (`dependsOn`)

You can declare that one profile depends on another. This is used for two things:
1.  **Validation:** NxDI can warn you if you try to activate a profile without its dependencies also being active.
2.  **Logical Grouping:** It helps you organize your DI setup in a modular way.

**Note:** `dependsOn` does *not* automatically activate dependencies or create an inheritance model. It's a tool for validation and organization.

```dart
nx.createProfile(name: 'core', priority: 0);
nx.createProfile(name: 'feature_auth', priority: 10, dependsOn: ['core']);

// This will automatically activate the 'core' profile first.
await nx.activateProfile('feature_auth');
```

## 🛠️ Advanced Registration Techniques

### Asynchronous Services

For services that require asynchronous setup (e.g., initializing a database), use `registerSingletonAsync`.

```dart
class DatabaseService {
  Future<void> initialize() async {
    // Simulate connecting to a database
    await Future.delayed(const Duration(seconds: 1));
    print('Database connected!');
  }
}

// Register the async service
nx.registerSingletonAsync<DatabaseService>(() async {
  final service = DatabaseService();
  await service.initialize();
  return service;
});

// To resolve it, you must use getAsync
print('Fetching database...');
final db = await nx.getAsync<DatabaseService>(); // "Database connected!" prints here.
print('Database is ready!');
```

### Parameterized Factories

Sometimes you need to pass runtime values to a factory. NxDI supports factories with up to two parameters.

```dart
class ReportGenerator {
  final User user;
  final String reportType;
  ReportGenerator(this.user, this.reportType);
}

// Register a factory with two parameters
nx.registerFactoryParam2<ReportGenerator, User, String>(
  (user, type) => ReportGenerator(user, type),
);

// Resolve it by passing the parameters to get()
final currentUser = User(name: 'Alice');
final generator = nx.get<ReportGenerator>(param1: currentUser, param2: 'PDF');
```

### Using `RegistrationOptions`

The `options` parameter on registration methods gives you fine-grained control.

```dart
nx.registerSingleton<MyService>(
  MyService(),
  options: RegistrationOptions(
    // Set to true to allow this registration to replace an existing one.
    allowOverride: true,

    // Provide a custom function to be called when the service is disposed.
    // This takes precedence over the Disposable interface.
    disposeFunction: (service) => service.customCleanup(),
  ),
);
```
See the [API Reference](#registrationoptions-1) for all available options.

## 🗑️ Memory Management & Disposal

NxDI helps you prevent memory leaks by providing a clear disposal mechanism.

### The `Disposable` Interfaces

If your service class implements `Disposable` or `AsyncDisposable`, NxDI will automatically call its `dispose` method when the service is cleaned up.

```dart
import 'package:nx_di/nx_di.dart';

class MyController implements Disposable {
  final _streamController = StreamController<int>();

  @override
  void dispose() {
    // This will be called automatically by NxDI
    print('Closing stream controller!');
    _streamController.close();
  }
}
```

### Manual Cleanup: `reset` and `unregister`

-   `unregister<T>()`: Removes a single service registration. If the instance is `Disposable`, its `dispose()` method is called.
-   `reset()`: Clears the **entire locator**, removing all registrations and disposing of all `Disposable` instances. This is perfect for cleaning up between tests or on user logout.

```dart
// Register the controller
nx.registerSingleton(MyController());

// ... use the controller ...

// Unregister it, which will trigger its dispose() method
await nx.unregister<MyController>(); // "Closing stream controller!" is printed.
```

## 🧪 Testing with NxDI

### The Golden Rule: Isolate Your Locator

**Never** use a global locator instance across different tests. Doing so will cause side effects and lead to flaky, unreliable tests. Always create a new, isolated locator for each test or test group.

### A Robust Testing Pattern

The recommended pattern is to use `setUp` and `tearDown` to manage the locator's lifecycle.

```dart
void main() {
  group('MyService Tests', () {
    late NxLocator testLocator;

    setUp(() {
      // 1. Create a fresh, isolated locator before each test
      testLocator = NxLocator.asNewInstance();
      
      // 2. Register your mocks and dependencies
      testLocator.registerSingleton<ApiService>(MockApiService());
      testLocator.registerFactory<MyService>(() => MyService(testLocator.get<ApiService>()));
    });

    tearDown(() async {
      // 3. Clean up everything after each test to prevent leaks
      await testLocator.reset();
    });

    test('should use the mocked api service', () {
      final myService = testLocator.get<MyService>();
      // ... your test logic ...
      expect(myService.api, isA<MockApiService>());
    });
  });
}
```

### Using Profiles for Advanced Testing

You can use profiles to easily switch between different testing configurations, such as unit vs. integration tests.

```dart
// In setUp...
testLocator.createProfile(name: 'unit_test', priority: 100);
testLocator.registerSingleton<Database>(MockDatabase(), profileName: 'unit_test');

testLocator.createProfile(name: 'integration_test', priority: 100);
testLocator.registerSingleton<Database>(RealDatabase(), profileName: 'integration_test');

// In a unit test...
await testLocator.activateProfile('unit_test');
final db = testLocator.get<Database>(); // Returns MockDatabase

// In an integration test...
await testLocator.activateProfile('integration_test');
final db = testLocator.get<Database>(); // Returns RealDatabase
```

## 📚 Full API Reference

### Locator Methods

| Method | Description |
| :--- | :--- |
| **Registration** | |
| `registerSingleton<T>(T instance, ...)` | Registers an eager singleton. |
| `registerLazySingleton<T>(FactoryFunc<T> factory, ...)` | Registers a singleton that is created on first use. |
| `registerFactory<T>(FactoryFunc<T> factory, ...)` | Registers a factory that creates a new instance each time. |
| `registerSingletonAsync<T>(FactoryFuncAsync<T> factory, ...)` | Registers a singleton with an async initialization function. |
| `registerFactoryParam<T, P1>(...)` | Registers a factory with one parameter. |
| `registerFactoryParam2<T, P1, P2>(...)` | Registers a factory with two parameters. |
| **Resolution** | |
| `get<T>({String? instanceName, P1? param1, P2? param2})` | Resolves a service instance. Throws if not found. |
| `tryGet<T>({...})` | Safely resolves a service instance. Returns `null` if not found. |
| `getAsync<T>({...})` | Resolves an asynchronously registered service. |
| `isRegistered<T>({String? instanceName})` | Checks if a service is registered in any active profile. |
| **Profile Management** | |
| `createProfile({required String name, int priority, ...})` | Creates a new, inactive profile. |
| `activateProfile(String profileName)` | Activates a profile, making its services available for resolution. |
| `deactivateProfile(String profileName, {bool dispose})` | Deactivates a profile, optionally disposing its services. |
| `switchToProfiles(Set<String> profileNames)` | Activates a specific set of profiles, deactivating all others. |
| **Cleanup** | |
| `unregister<T>({String? instanceName, bool dispose})` | Removes a single service registration, optionally disposing it. |
| `reset({bool dispose})` | Clears all registrations from the locator, optionally disposing them. |

### RegistrationOptions

This class is passed to the `options` parameter of registration methods.

| Property | Type | Description |
| :--- | :--- | :--- |
| `allowOverride` | `bool` | If `true`, this registration can replace an existing one for the same type. Defaults to `false`. |
| `disposeFunction` | `DisposeFunc<T>?` | A custom function to call for disposal, overriding the `Disposable` interface. |
| `asyncDisposeFunction` | `DisposeFuncAsync<T>?` | An async version of `disposeFunction`. |

## 🚑 Troubleshooting

### Common Errors

-   **`ObjectNotFoundException`**: You called `get<T>()` for a type that was never registered, or was registered in a profile that is not currently active.
-   **`ObjectAlreadyRegisteredException`**: You tried to register a type that is already registered without setting `allowOverride: true`.
-   **`CircularDependencyException`**: Two or more of your services depend on each other in a way that creates an infinite loop (e.g., Service A needs Service B, and Service B needs Service A). You can often solve this by making one of them a `LazySingleton`.

### Common Pitfalls

-   **Using a global locator in tests:** This is the most common cause of flaky tests. Always use `NxLocator.asNewInstance()` inside your test `setUp`.
-   **Forgetting to `await activateProfile()`:** Profile activation is an async operation.
-   **Forgetting `allowOverride: true`:** When using profiles to override a base service, you must explicitly allow it in the higher-priority profile's registration.