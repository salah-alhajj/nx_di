# 🔄 Migration Guide: from get_it to NxDI

This guide covers the manual process of migrating an existing project from `get_it` to `nx_di`. The process is straightforward and primarily involves updating package imports and instance calls.

## 📝 Manual Migration Steps

### Step 1: Update `pubspec.yaml`

First, replace `get_it` with `nx_di` in your `pubspec.yaml` file.

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # remove_this_line: get_it: ^7.x.x 
  nx_di: ^0.7.3 # add_this_line
```

Then, run `flutter pub get` or `dart pub get` to update your dependencies.

### Step 2: Replace Imports

In your Dart files, replace the `get_it` import with the `nx_di` import.

```dart
// Before
import 'package:get_it/get_it.dart';

// After
import 'package:nx_di/nx_di.dart';
```

### Step 3: Update Locator Instance and Calls

The final step is to replace the `GetIt.instance` (or `GetIt.I`) calls with your `NxLocator` instance. We recommend creating a global instance for your app.

```dart
// in your service_locator.dart or similar
final nx = NxLocator.asNewInstance();

// Before
GetIt.instance.registerSingleton<ApiService>(ApiService());
final api = GetIt.instance<ApiService>();

// After
nx.registerSingleton<ApiService>(ApiService());
final api = nx.get<ApiService>();
```

A global search-and-replace for `GetIt.instance` and `GetIt.I` to `nx` (or your chosen variable name) will handle most cases.

## ⚠️ API Differences to Note

While the API is very similar, there are a few key differences to be aware of during migration:

| get_it Feature | NxDI Equivalent | Notes |
| :--- | :--- | :--- |
| `allReady()` / `isReady()` | `getAsync()` | `nx_di` handles async initialization implicitly. When you `await nx.getAsync<T>()`, it ensures the async factory has completed before returning the instance. There is no separate readiness signal. |
| `registerSingleton(..., dispose: ...)` | Implement `Disposable` | In `nx_di`, automatic cleanup relies on your service class implementing the `Disposable` or `AsyncDisposable` interface. |
| Overriding a registration | `RegistrationOptions(allowOverride: true)` | `nx_di` prevents accidental overrides. You must explicitly allow it. |

## 🧪 Migrating Tests

The pattern for testing is very similar. The main change is to use `NxLocator.asNewInstance()` to ensure each test has an isolated container.

```dart
// Before: get_it in tests
void main() {
  setUp(() {
    GetIt.instance.registerSingleton<TestService>(MockTestService());
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  test('should work', () {
    final service = GetIt.instance.get<TestService>();
    expect(service, isA<MockTestService>());
  });
}

// After: NxDI in tests
void main() {
  late NxLocator testLocator;

  setUp(() {
    testLocator = NxLocator.asNewInstance();
    testLocator.registerSingleton<TestService>(MockTestService());
  });

  tearDown(() async {
    await testLocator.reset();
  });

  test('should work', () {
    final service = testLocator.get<TestService>();
    expect(service, isA<MockTestService>());
  });
}
```

## 🎭 Adopting Profiles (Optional)

After migrating, you can start using the multi-profile system. For example, you can move your test mocks into a dedicated 'test' profile.

```dart
// 1. Create a profile for your test environment
testLocator.createProfile(name: 'test', priority: 100);

// 2. Register mocks into that profile
testLocator.registerSingleton<ApiService>(
  MockApiService(),
  profileName: 'test',
  options: RegistrationOptions(allowOverride: true), // If overriding a base service
);

// 3. Activate the profile before running tests
await testLocator.activateProfile('test');

// Now, testLocator.get<ApiService>() will return MockApiService.
```
