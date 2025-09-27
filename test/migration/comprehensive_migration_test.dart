import 'dart:io';
import 'package:flutter_test/flutter_test.dart'
    hide test, group, setUp, tearDown, expect, setUpAll, tearDownAll;
import 'package:nx_di/src/migration/get_it_migrator.dart';
import 'package:nx_di/src/core/nx_locator.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Comprehensive Migration Tests', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('nx_di_migration_test');
    });

    tearDownAll(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('migrates complete project with multiple files and patterns', () async {
      // Create a realistic project structure with various get_it usage patterns
      final testFiles = {
        'lib/main.dart': '''
import 'package:get_it/get_it.dart';

class ServiceA {}

void setupDI() {
  GetIt.instance.registerFactory<ServiceA>(() => ServiceA());
  GetIt.instance.registerLazySingleton<ServiceA>(() => ServiceA());
  GetIt.instance.registerSingleton<ServiceA>(ServiceA());
}

void useServices() {
  final serviceA = GetIt.instance.get<ServiceA>();
  final isRegistered = GetIt.instance.isRegistered<ServiceA>();
}
''',
        'lib/services/api_service.dart': '''
import 'package:get_it/get_it.dart';

class ApiService {}

void setup() {
  GetIt.I.registerSingleton<ApiService>(
    ApiService(),
    signalReady: true,
  );

  final isReady = GetIt.I.isReady<ApiService>();
}
''',
        'lib/di/service_locator.dart': '''
import 'package:get_it/get_it.dart';

void useGetIt() {
  GetIt.instance.registerFactory(() => Object());
  final obj = GetIt.instance.get<Object>();
}
''',
        'test/widget_test.dart': '''
import 'package:get_it/get_it.dart';

void testSetup() {
  GetIt.instance.registerFactory(() => Object());
}
''',
        'lib/utils/helpers.dart': '''
import 'dart:io';

class MyService {
  void doSomething() {
    print('Hello World');
  }
}
''', // File without get_it usage
      };

      // Create all test files
      for (final entry in testFiles.entries) {
        final file = File('${tempDir.path}/${entry.key}');
        await file.create(recursive: true);
        await file.writeAsString(entry.value);
      }

      final migrator = GetItMigrator();
      migrator.config = migrator.migrationConfig(
        rootPath: tempDir.path,
        includePatterns: ['**/*.dart'],
        excludePatterns: [],
        createBackup: true,
        globalInstanceName: 'nx',
        addNxDiImport: true,
        removeGetItImport: true,
        dryRun: false,
      );

      final stats = await migrator.migrate();

      // Verify migration stats
      expect(stats.filesProcessed, equals(5)); // All files processed
      expect(stats.filesModified, equals(4)); // Only files with get_it usage
      expect(stats.importsReplaced, greaterThan(0));
      expect(stats.instancesReplaced, greaterThan(0));

      // Verify specific file transformations
      final mainContent = await File(
        '${tempDir.path}/lib/main.dart',
      ).readAsString();
      expect(mainContent, contains('package:nx_di/nx_di.dart'));
      expect(mainContent, isNot(contains('package:get_it/get_it.dart')));
      expect(mainContent, contains('nx.registerFactory'));
      expect(mainContent, contains('nx.registerLazySingleton'));
      expect(mainContent, contains('nx.registerSingleton'));
      expect(mainContent, contains('nx.get<ServiceA>'));
      expect(mainContent, contains('nx.isRegistered<ServiceA>'));

      final apiContent = await File(
        '${tempDir.path}/lib/services/api_service.dart',
      ).readAsString();
      expect(apiContent, contains('package:nx_di/nx_di.dart'));
      expect(apiContent, contains('nx.registerSingleton'));
      expect(apiContent, contains('signalReady: true'));
      expect(apiContent, contains('nx.isRegistered<ApiService>'));

      // Verify file without get_it usage remains unchanged
      final helperContent = await File(
        '${tempDir.path}/lib/utils/helpers.dart',
      ).readAsString();
      expect(helperContent, equals(testFiles['lib/utils/helpers.dart']));

      // Verify backups were created
      for (final fileName in [
        'lib/main.dart',
        'lib/services/api_service.dart',
        'lib/di/service_locator.dart',
        'test/widget_test.dart',
      ]) {
        final backupFile = File('${tempDir.path}/$fileName.backup');
        expect(await backupFile.exists(), isTrue);
      }
    });
  });

  group('Migration Tool Integration with Enhanced Lazy Singletons', () {
    late NxLocator nx;

    setUp(() {
      nx = NxLocator.asNewInstance();
    });

    test('migrated lazy singletons use our ultra-fast optimization', () {
      // Test that lazy singletons created through migration work with our optimizations
      nx.registerLazySingleton<ServiceA>(() => ServiceA());

      final service1 = nx.get<ServiceA>();
      final service2 = nx.get<ServiceA>();

      // Should be the same instance (lazy singleton behavior)
      expect(service1, same(service2));
      expect(service1, isA<ServiceA>());
    });

    test('performance characteristics match optimized implementation', () {
      // Register multiple lazy singletons to test performance
      for (int i = 0; i < 100; i++) {
        nx.registerLazySingleton<ServiceA>(
          () => ServiceA(),
          instanceName: 'service_$i',
        );
      }

      final stopwatch = Stopwatch()..start();

      // Access all lazy singletons multiple times
      for (int i = 0; i < 100; i++) {
        for (int j = 0; j < 10; j++) {
          final service = nx.get<ServiceA>(instanceName: 'service_$i');
          expect(service, isA<ServiceA>());
        }
      }

      stopwatch.stop();

      // Performance should be excellent due to our optimizations
      expect(
        stopwatch.elapsedMicroseconds,
        lessThan(50000),
      ); // Less than 50ms total
    });

    test('migrated code works with profile system', () {
      // Create profiles as would be done after migration
      nx.createProfile(name: 'dev', priority: 100);
      nx.createProfile(name: 'prod', priority: 200);

      // Register services in different profiles
      nx.registerLazySingleton<ServiceA>(() => ServiceA(), profileName: 'dev');
      nx.registerLazySingleton<ServiceB>(
        () => ServiceB(ServiceA()),
        profileName: 'prod',
      );

      expect(nx.isRegistered<ServiceA>(profileName: 'dev'), isTrue);
      expect(nx.isRegistered<ServiceB>(profileName: 'prod'), isTrue);
    });
  });
}
