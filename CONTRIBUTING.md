# 🤝 Contributing to NxDI

We welcome contributions to NxDI! This guide will help you get started with contributing to the project.

## 🌟 Ways to Contribute

- 🐛 **Bug Reports**: Report issues you encounter
- 💡 **Feature Requests**: Suggest new features or improvements
- 📝 **Documentation**: Improve docs, examples, or guides
- 🧪 **Testing**: Add tests or improve test coverage
- ⚡ **Performance**: Optimize performance or add benchmarks
- 🔧 **Code**: Fix bugs or implement new features

## 🚀 Getting Started

### Prerequisites

- **Dart SDK** 3.0+ or Flutter 3.10+
- **Git** for version control
- **GitHub account** for pull requests

### Development Setup

```bash
# 1. Fork the repository on GitHub
# 2. Clone your fork
git clone https://github.com/salah-alhajj/nx_di.git
cd nx_di

# 3. Install dependencies
dart pub get

# 4. Run tests to ensure everything works
dart test

# 5. Create a feature branch
git checkout -b feature/your-feature-name
```

### Project Structure

```
nx_di/
├── lib/
│   ├── nx_di.dart              # Main export file
│   └── src/
│       ├── core/               # Core DI functionality
│       ├── profiles/           # Profile system
│       ├── migration/          # Migration tools
│       ├── types/              # Type definitions
│       ├── exceptions/         # Exception classes
│       └── utils/              # Utility classes
├── test/
│   ├── core/                   # Core functionality tests
│   ├── profiles/               # Profile system tests
│   ├── migration/              # Migration tool tests
│   └── benchmark/              # Performance benchmarks
├── example/                    # Usage examples
├── docs/                       # Documentation
└── tool/                       # Development tools
```

## 📝 Development Guidelines

### Code Style

We follow Dart's official style guide with these additions:

```dart
// ✅ Good: Use descriptive names
class ServiceRegistration<T extends Object> {
  final FactoryFunc<T> factoryFunc;
  final RegistrationOptions<T> options;
}

// ❌ Avoid: Short, unclear names
class SR<T> {
  final f;
  final o;
}

// ✅ Good: Document public APIs
/// Registers a singleton instance in the container.
///
/// The [instance] will be returned every time [T] is requested.
/// Optionally specify [profileName] to register in a specific profile.
void registerSingleton<T extends Object>(
  T instance, {
  String? profileName,
  RegistrationOptions<T>? options,
});

// ✅ Good: Use meaningful comments for complex logic
// Performance optimization: Use late final for zero-allocation access
late final T _lazyInstance = factoryFunc!();
```

### Testing Requirements

All contributions must include appropriate tests:

```dart
// ✅ Test public API behavior
test('registerSingleton should return same instance', () {
  final service = ServiceA();
  nx.registerSingleton<ServiceA>(service);

  final retrieved = nx.get<ServiceA>();
  expect(retrieved, same(service));
});

// ✅ Test error conditions
test('get should throw when service not registered', () {
  expect(
    () => nx.get<UnregisteredService>(),
    throwsA(isA<ObjectNotFoundException>()),
  );
});

// ✅ Test performance characteristics
test('lazy singleton should be created only once', () {
  var creationCount = 0;
  nx.registerLazySingleton<ServiceA>(() {
    creationCount++;
    return ServiceA();
  });

  nx.get<ServiceA>();
  nx.get<ServiceA>();

  expect(creationCount, equals(1));
});
```

### Performance Considerations

NxDI prioritizes performance. Consider these guidelines:

```dart
// ✅ Good: Minimize allocations in hot paths
T getInstance() => _lazyInstance; // Direct field access

// ❌ Avoid: Unnecessary allocations
T getInstance() => _cache[key] ?? _create(); // Map lookup overhead

// ✅ Good: Use late final for lazy initialization
late final T _instance = _factory();

// ❌ Avoid: Nullable fields with runtime checks
T? _instance;
T getInstance() {
  _instance ??= _factory(); // Null check overhead
  return _instance!;
}
```

## 🐛 Bug Reports

When reporting bugs, please include:

### Bug Report Template

```markdown
## 🐛 Bug Report

**Description**
Clear description of the bug

**Steps to Reproduce**
1. Step one
2. Step two
3. Step three

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- NxDI version:
- Dart/Flutter version:
- Platform:

**Code Sample**
```dart
// Minimal code that reproduces the issue
```

**Additional Context**
Any other relevant information
```

### Example Bug Report

```markdown
## 🐛 Service not found after profile deactivation

**Description**
Services remain accessible after their profile is deactivated

**Steps to Reproduce**
1. Create profile and register service
2. Activate profile and access service
3. Deactivate profile
4. Try to access service again

**Expected Behavior**
Should throw ObjectNotFoundException

**Actual Behavior**
Service is still accessible

**Code Sample**
```dart
nx.createProfile(name: 'test', priority: 100);
nx.registerSingleton<Service>(Service(), profileName: 'test');
nx.activateProfile('test');
final service1 = nx.get<Service>(); // Works

nx.deactivateProfile('test');
final service2 = nx.get<Service>(); // Should throw but doesn't
```
```

## 💡 Feature Requests

When suggesting features, please include:

### Feature Request Template

```markdown
## 💡 Feature Request

**Feature Description**
Clear description of the proposed feature

**Use Case**
Why is this feature needed? What problem does it solve?

**Proposed API**
How should the feature work? Include code examples.

**Alternatives Considered**
Other ways to solve the problem

**Additional Context**
Any other relevant information
```

### Example Feature Request

```markdown
## 💡 Conditional Service Registration

**Feature Description**
Ability to register services conditionally based on runtime conditions

**Use Case**
Register different implementations based on feature flags or environment variables without using profiles.

**Proposed API**
```dart
nx.registerConditional<ApiService>(
  condition: () => FeatureFlags.useNewApi,
  factory: () => NewApiService(),
  fallback: () => LegacyApiService(),
);
```

**Alternatives Considered**
- Using profiles (more heavyweight)
- Factory with internal condition (less clean)
```

## 🔧 Pull Request Process

### Before You Start

1. **Check existing issues** to avoid duplicated work
2. **Open an issue** for large features to discuss approach
3. **Create a feature branch** from `main`

### Making Changes

```bash
# 1. Create feature branch
git checkout -b feature/conditional-registration

# 2. Make your changes
# 3. Add tests for new functionality
# 4. Ensure all tests pass
dart test

# 5. Format code
dart format .

# 6. Analyze code
dart analyze

# 7. Run benchmarks if performance-related
dart run test/benchmark/nx_vs_getit_benchmark.dart
```

### Pull Request Requirements

- ✅ **All tests pass**: `dart test` must succeed
- ✅ **Code formatted**: `dart format .` applied
- ✅ **No analyzer warnings**: `dart analyze` clean
- ✅ **Tests included**: New functionality has tests
- ✅ **Documentation updated**: Public APIs documented
- ✅ **Performance maintained**: No significant regressions

### Pull Request Template

```markdown
## 📋 Pull Request

**Description**
What does this PR do?

**Type of Change**
- [ ] Bug fix
- [ ] New feature
- [ ] Performance improvement
- [ ] Documentation update
- [ ] Refactoring

**Testing**
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Benchmarks run (if performance-related)
- [ ] Manual testing completed

**Breaking Changes**
- [ ] This PR introduces breaking changes
- [ ] Migration guide updated (if applicable)

**Checklist**
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests pass locally
- [ ] No new analyzer warnings

**Related Issues**
Fixes #123, Closes #456
```

## 🧪 Testing Guidelines

### Test Categories

1. **Unit Tests**: Test individual components
2. **Integration Tests**: Test component interactions
3. **Performance Tests**: Benchmark critical paths
4. **Migration Tests**: Test migration tool functionality

### Writing Good Tests

```dart
// ✅ Good: Descriptive test names
test('registerLazySingleton should create instance only on first access', () {
  // Test implementation
});

// ❌ Avoid: Vague test names
test('lazy singleton works', () {
  // Test implementation
});

// ✅ Good: Test one thing per test
test('registerSingleton should store instance', () {
  nx.registerSingleton<Service>(Service());
  expect(nx.isRegistered<Service>(), isTrue);
});

test('registerSingleton should return same instance', () {
  final service = Service();
  nx.registerSingleton<Service>(service);
  expect(nx.get<Service>(), same(service));
});

// ❌ Avoid: Multiple assertions in one test
test('registerSingleton works correctly', () {
  final service = Service();
  nx.registerSingleton<Service>(service);
  expect(nx.isRegistered<Service>(), isTrue); // First assertion
  expect(nx.get<Service>(), same(service)); // Second assertion
});
```

### Test Structure

```dart
void main() {
  group('Feature Group', () {
    late NxLocator nx;

    setUp(() {
      nx = NxLocator.asNewInstance();
    });

    tearDown(() async {
      await nx.reset();
    });

    test('should do something specific', () {
      // Arrange
      final service = MockService();

      // Act
      nx.registerSingleton<Service>(service);
      final result = nx.get<Service>();

      // Assert
      expect(result, same(service));
    });
  });
}
```

## 🚀 Performance Guidelines

### Benchmarking

When making performance changes:

```bash
# Run baseline benchmarks
dart run test/benchmark/nx_vs_getit_benchmark.dart > baseline.txt

# Make your changes
# Run benchmarks again
dart run test/benchmark/nx_vs_getit_benchmark.dart > optimized.txt

# Compare results
diff baseline.txt optimized.txt
```

### Performance Best Practices

```dart
// ✅ Good: Minimize allocations in hot paths
class ServiceKey {
  const ServiceKey(this.type, this.name); // Const constructor
  final Type type;
  final String? name;
}

// ❌ Avoid: Allocations in service resolution
String _createKey(Type type, String? name) {
  return '$type:${name ?? ''}'; // String allocation
}

// ✅ Good: Use late final for lazy initialization
late final T _instance = _factory();

// ❌ Avoid: Locks or synchronization in resolution
final Lock _lock = Lock();
T getInstance() {
  return _lock.synchronized(() => _instance);
}
```

## 📚 Documentation

### API Documentation

```dart
/// Registers a factory function for type [T].
///
/// The factory function [factoryFunc] will be called every time
/// an instance of [T] is requested via [get].
///
/// Example:
/// ```dart
/// nx.registerFactory<UserService>(() => UserService());
/// final service = nx.get<UserService>(); // Creates new instance
/// ```
///
/// Parameters:
/// - [factoryFunc]: Function that creates instances of [T]
/// - [profileName]: Optional profile to register in
/// - [instanceName]: Optional name for named instances
/// - [options]: Additional registration options
///
/// Throws:
/// - [ServiceAlreadyRegisteredException] if [T] is already registered
/// - [ProfileNotFoundException] if [profileName] doesn't exist
void registerFactory<T extends Object>(
  FactoryFunc<T> factoryFunc, {
  String? profileName,
  String? instanceName,
  RegistrationOptions<T>? options,
});
```

### Example Documentation

```dart
// example/basic_usage.dart
import 'package:nx_di/nx_di.dart';

/// Basic NxDI usage example
///
/// This example demonstrates:
/// - Service registration
/// - Service retrieval
/// - Different registration types
void main() {
  // Register a singleton
  nx.registerSingleton<Logger>(ConsoleLogger());

  // Register a factory
  nx.registerFactory<UserService>(() => UserService());

  // Register a lazy singleton
  nx.registerLazySingleton<Database>(() => Database());

  // Get services
  final logger = nx.get<Logger>();
  final userService = nx.get<UserService>();
  final database = nx.get<Database>();

  // Use services
  logger.info('Application started');
  userService.createUser('John Doe');
  database.store('user_data');
}
```

## 🏷️ Release Process

### Version Management

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist

- [ ] All tests pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped in pubspec.yaml
- [ ] Performance benchmarks run
- [ ] Migration guide updated (if needed)

## 🎯 Development Focus Areas

We're especially interested in contributions in these areas:

### High Priority
- 🚀 **Performance optimizations**: Faster service resolution
- 🧪 **Test coverage**: Increase test coverage to 100%
- 📚 **Documentation**: More examples and guides
- 🔧 **Tooling**: Better migration and debugging tools

### Medium Priority
- 🎭 **Profile enhancements**: Advanced profile features
- 📊 **Monitoring**: Better diagnostics and metrics
- 🛡️ **Error handling**: More helpful error messages
- 🔌 **Extensions**: Utility extensions and helpers

### Low Priority
- 🎨 **Code organization**: Refactoring and cleanup
- 📱 **Platform support**: Web/desktop optimizations
- 🔄 **CI/CD**: Automation improvements

## 💬 Communication

### Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and general discussion
- **Pull Requests**: Code contributions and reviews

### Communication Guidelines

- Be respectful and constructive
- Provide context and examples
- Ask questions if unclear
- Help others when possible

## 🙏 Recognition

Contributors are recognized in:

- **CONTRIBUTORS.md**: List of all contributors
- **Release notes**: Major contributions highlighted
- **Documentation**: Credits in relevant sections

### Contributor Levels

- **Contributor**: Made at least one merged PR
- **Regular Contributor**: Made multiple PRs or significant contribution
- **Maintainer**: Has commit access and helps with reviews
- **Core Team**: Makes architectural decisions

## 📄 License

By contributing to NxDI, you agree that your contributions will be licensed under the same [MIT License](LICENSE) as the project.

---

## 🚀 Ready to Contribute?

1. **Fork the repository** on GitHub
2. **Set up your development environment** following this guide
3. **Pick an issue** or create a feature request
4. **Make your changes** following our guidelines
5. **Submit a pull request** for review

**Questions?** Open a [GitHub Discussion](https://github.com/salah-alhajj/nx_di/discussions) - we're here to help!

Thank you for contributing to NxDI! 🎉