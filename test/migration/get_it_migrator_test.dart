import 'dart:io';
import 'package:test/test.dart';
import 'package:nx_di/src/migration/get_it_migrator.dart';

void main() {
  group('GetItMigrator', () {
    late Directory tempDir;
    late GetItMigrator migrator;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('get_it_migrator_test');
      migrator = GetItMigrator();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('migrates a simple file correctly', () async {
      final file = File('${tempDir.path}/main.dart');
      await file.writeAsString('''
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void main() {
  getIt.registerSingleton<String>('Hello');
  print(getIt<String>());
}
''');

      migrator.config = MigrationConfig(rootPath: tempDir.path, dryRun: false);

      final stats = await migrator.migrate();

      expect(stats.filesModified, 1);
      expect(stats.importsReplaced, 1);
      expect(stats.instancesReplaced, 2);

      final migratedContent = await file.readAsString();
      expect(migratedContent, contains("import 'package:nx_di/nx_di.dart';"));
      expect(migratedContent, contains('final nx = nx;'));
      expect(
        migratedContent,
        contains('nx.registerSingleton<String>(\'Hello\');'),
      );
    });

    test('handles various GetIt syntaxes', () async {
      final file = File('${tempDir.path}/complex.dart');
      await file.writeAsString('''
import 'package:get_it/get_it.dart';

GetIt getIt = GetIt.I;

class Service {}

void setup() {
  GetIt.instance.registerLazySingleton(() => Service());
  getIt.allReady().then((_) {
    print('Ready!');
  });
}
''');

      migrator.config = MigrationConfig(rootPath: tempDir.path, dryRun: false);

      await migrator.migrate();

      final migratedContent = await file.readAsString();
      expect(migratedContent, contains('GetIt nx = nx;'));
      expect(
        migratedContent,
        contains('nx.registerLazySingleton(() => Service());'),
      );
      expect(
        migratedContent,
        contains('/* TODO: allReady() not available in nx-di.'),
      );
    });

    test('dry run does not modify files', () async {
      final filePath = '${tempDir.path}/dry_run_test.dart';
      final file = File(filePath);
      final originalContent = '''
import 'package:get_it/get_it.dart';
final getIt = GetIt.instance;
''';
      await file.writeAsString(originalContent);

      migrator.config = MigrationConfig(rootPath: tempDir.path, dryRun: true);

      final stats = await migrator.migrate();

      expect(stats.filesModified, 3);

      final contentAfterMigration = await file.readAsString();
      expect(contentAfterMigration, originalContent);
    });
  });
}
