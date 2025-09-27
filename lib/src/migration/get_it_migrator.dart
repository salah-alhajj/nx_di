import 'dart:io';

class MigrationStats {
  int filesProcessed = 0;
  int filesModified = 0;
  int importsReplaced = 0;
  int instancesReplaced = 0;
  int methodsReplaced = 0;
  List<String> modifiedFiles = [];
  List<String> errors = [];

  @override
  String toString() =>
      '''
Migration completed!
- Files processed: $filesProcessed
- Files modified: $filesModified  
- Imports replaced: $importsReplaced
- Instances replaced: $instancesReplaced
- Methods replaced: $methodsReplaced
- Modified files: ${modifiedFiles.length}
- Errors: ${errors.length}
''';
}

class MigrationConfig {
  /// Root directory to process (default: current directory)
  final String rootPath;

  /// File patterns to include (default: *.dart)
  final List<String> includePatterns;

  /// File patterns to exclude (default: none)
  final List<String> excludePatterns;

  /// Whether to create backup files
  final bool createBackup;

  /// Whether to use 'nx' or 'di' as the global instance name
  final String globalInstanceName;

  /// Whether to add nx-di import automatically
  final bool addNxDiImport;

  /// Whether to remove get_it import after migration
  final bool removeGetItImport;

  /// Whether to run in dry-run mode (no file modifications)
  final bool dryRun;

  const MigrationConfig({
    this.rootPath = '.',
    this.includePatterns = const ['**/*.dart'],
    this.excludePatterns = const [],
    this.createBackup = true,
    this.globalInstanceName = 'nx',
    this.addNxDiImport = true,
    this.removeGetItImport = true,
    this.dryRun = false,
  });
}

/// Automatic migration tool from get_it to nx-di
class GetItMigrator {
  // singleton
  static final GetItMigrator _instance = GetItMigrator._();
  factory GetItMigrator() => _instance;
  GetItMigrator._();
  static GetItMigrator get instance => _instance;

  /// Migration configuration

  late MigrationConfig config;
  // define migrationConfig for config
  MigrationConfig migrationConfig({
    required String rootPath,
    required List<String> includePatterns,
    required List<String> excludePatterns,
    required bool createBackup,
    required String globalInstanceName,
    required bool addNxDiImport,
    required bool removeGetItImport,
    required bool dryRun,
  }) {
    return MigrationConfig(
      rootPath: rootPath,
      includePatterns: includePatterns,
      excludePatterns: excludePatterns,
      createBackup: createBackup,
      globalInstanceName: globalInstanceName,
      addNxDiImport: addNxDiImport,
      removeGetItImport: removeGetItImport,
      dryRun: dryRun,
    );
  }

  final MigrationStats stats = MigrationStats();

  // GetItMigrator({required this.config});

  /// Run the migration process
  Future<MigrationStats> migrate() async {
    print('🚀 Starting get_it to nx-di migration...');
    print('Root path: ${config.rootPath}');
    print('Global instance: ${config.globalInstanceName}');
    print('Dry run: ${config.dryRun}');
    print('');

    try {
      final dartFiles = await _findDartFiles();
      print('Found ${dartFiles.length} Dart files to process\n');

      for (final file in dartFiles) {
        await _processFile(file);
      }

      _printSummary();
      return stats;
    } catch (e) {
      stats.errors.add('Migration failed: $e');
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Find all Dart files to process
  Future<List<File>> _findDartFiles() async {
    final List<File> dartFiles = [];
    final directory = Directory(config.rootPath);

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        if (_shouldProcessFile(entity.path)) {
          dartFiles.add(entity);
        }
      }
    }

    return dartFiles;
  }

  /// Check if file should be processed based on include/exclude patterns
  bool _shouldProcessFile(String filePath) {
    // Skip generated files
    if (filePath.contains('.g.dart') ||
        filePath.contains('.freezed.dart') ||
        filePath.contains('.gr.dart')) {
      return false;
    }

    // Apply exclude patterns
    for (final pattern in config.excludePatterns) {
      if (_matchesPattern(filePath, pattern)) {
        return false;
      }
    }

    // Apply include patterns (default: all .dart files)
    if (config.includePatterns.isEmpty) return true;

    for (final pattern in config.includePatterns) {
      if (_matchesPattern(filePath, pattern)) {
        return true;
      }
    }

    return false;
  }

  /// Simple pattern matching (supports * wildcards)
  bool _matchesPattern(String path, String pattern) {
    if (pattern == '**/*.dart') return path.endsWith('.dart');
    if (pattern.startsWith('**/')) {
      return path.endsWith(pattern.substring(3));
    }
    if (pattern.endsWith('/**')) {
      return path.startsWith(pattern.substring(0, pattern.length - 3));
    }
    return path.contains(pattern);
  }

  /// Process a single Dart file
  Future<void> _processFile(File file) async {
    stats.filesProcessed++;

    try {
      final originalContent = await file.readAsString();
      final modifiedContent = _migrateContent(originalContent, file.path);

      if (originalContent != modifiedContent) {
        stats.filesModified++;
        stats.modifiedFiles.add(file.path);

        if (!config.dryRun) {
          // Create backup if requested
          if (config.createBackup) {
            await _createBackup(file, originalContent);
          }

          // Write modified content
          await file.writeAsString(modifiedContent);
        }

        print('✅ Modified: ${file.path}');
      }
    } catch (e) {
      stats.errors.add('Error processing ${file.path}: $e');
      print('❌ Error processing ${file.path}: $e');
    }
  }

  /// Create backup file
  Future<void> _createBackup(File file, String originalContent) async {
    final backupFile = File('${file.path}.backup');
    await backupFile.writeAsString(originalContent);
  }

  /// Migrate content of a single file
  String _migrateContent(String content, String filePath) {
    String migratedContent = content;
    bool hasGetItImport = false;
    bool hasGetItUsage = false;

    // Check if file uses get_it
    if (content.contains('get_it') || content.contains('GetIt')) {
      hasGetItImport =
          content.contains("import 'package:get_it/get_it.dart'") ||
          content.contains('import "package:get_it/get_it.dart"');
      hasGetItUsage = content.contains('GetIt.') || content.contains('getIt.');
    }

    if (!hasGetItImport && !hasGetItUsage) {
      return content; // No get_it usage found
    }

    // 1. Replace imports
    migratedContent = _replaceImports(migratedContent);

    // 2. Replace GetIt instances
    migratedContent = _replaceInstances(migratedContent);

    // 3. Replace method calls
    migratedContent = _replaceMethods(migratedContent);

    // 4. Add nx-di import if needed
    if (config.addNxDiImport &&
        (migratedContent.contains('${config.globalInstanceName}.') ||
            migratedContent.contains('NxLocator'))) {
      migratedContent = _addNxDiImport(migratedContent);
    }

    return migratedContent;
  }

  /// Replace get_it imports with nx-di imports
  String _replaceImports(String content) {
    final importReplacements = {
      "import 'package:get_it/get_it.dart';":
          "import 'package:nx_di/nx_di.dart';",
      'import "package:get_it/get_it.dart";':
          'import "package:nx_di/nx_di.dart";',
    };

    String result = content;
    for (final entry in importReplacements.entries) {
      if (result.contains(entry.key)) {
        result = result.replaceAll(entry.key, entry.value);
        stats.importsReplaced++;
      }
    }

    // Remove get_it import if requested
    if (config.removeGetItImport) {
      result = result.replaceAll(
        // This improved regex handles various whitespaces and removes the entire line.
        RegExp(
          // FIX: Use triple quotes to allow " and ' inside the raw string.
          r'''^\s*import\s+['"]package:get_it/get_it\.dart['"];?\s*[\r\n]+''',
          multiLine: true,
        ),
        '',
      );
    }

    return result;
  }

  /// Replace GetIt instances with nx instances
  String _replaceInstances(String content) {
    final instanceReplacements = {
      'GetIt.instance': config.globalInstanceName,
      'GetIt.I': config.globalInstanceName,
      'getIt': config.globalInstanceName,
      'GetIt()': 'NxLocator()',
      'GetIt.asNewInstance()': 'NxLocator.asNewInstance()',
    };

    String result = content;
    for (final entry in instanceReplacements.entries) {
      if (result.contains(entry.key)) {
        result = result.replaceAll(entry.key, entry.value);
        stats.instancesReplaced++;
      }
    }

    return result;
  }

  /// Replace method calls that might have different signatures
  String _replaceMethods(String content) {
    String result = content;

    // Handle method calls that might need parameter adjustments
    final methodPatterns = [
      // registerSingleton with signalReady parameter
      RegExp(
        r'(\w+)\.registerSingleton<([^>]+)>\(\s*([^,]+),\s*signalReady:\s*true\s*\)',
      ),

      // registerLazySingleton with signalReady parameter
      RegExp(
        r'(\w+)\.registerLazySingleton<([^>]+)>\(\s*([^,]+),\s*signalReady:\s*true\s*\)',
      ),

      // allReady() method (not available in nx-di)
      RegExp(r'(\w+)\.allReady\(\)'),

      // isReady<T>() method
      RegExp(r'(\w+)\.isReady<([^>]+)>\(\)'),
    ];

    for (final pattern in methodPatterns) {
      final matches = pattern.allMatches(result).toList();
      for (final match in matches.reversed) {
        final replacement = _getMethodReplacement(match);
        if (replacement != null) {
          result = result.replaceRange(match.start, match.end, replacement);
          stats.methodsReplaced++;
        }
      }
    }

    return result;
  }

  /// Get replacement for specific method patterns
  String? _getMethodReplacement(RegExpMatch match) {
    final fullMatch = match.group(0)!;

    if (fullMatch.contains('signalReady: true')) {
      // Convert signalReady parameter to RegistrationOptions
      final instance = match.group(1)!;
      final type = match.group(2)!;
      final service = match.group(3)!;

      if (fullMatch.contains('registerSingleton')) {
        return '$instance.registerSingleton<$type>(\n'
            '  $service,\n'
            '  options: RegistrationOptions(signalReady: true),\n'
            ')';
      } else if (fullMatch.contains('registerLazySingleton')) {
        return '$instance.registerLazySingleton<$type>(\n'
            '  $service,\n'
            '  options: RegistrationOptions(signalReady: true),\n'
            ')';
      }
    } else if (fullMatch.contains('allReady()')) {
      // allReady() is not available in nx-di, suggest alternative
      return '/* TODO: allReady() not available in nx-di. '
          'Consider using individual isRegistered<T>() checks */';
    } else if (fullMatch.contains('isReady<')) {
      // isReady<T>() -> isRegistered<T>()
      final instance = match.group(1)!;
      final type = match.group(2)!;
      return '$instance.isRegistered<$type>()';
    }

    return null;
  }

  /// Add nx-di import to file if not present
  String _addNxDiImport(String content) {
    if (content.contains("import 'package:nx_di/nx_di.dart'") ||
        content.contains('import "package:nx_di/nx_di.dart"')) {
      return content; // Already has import
    }

    // Find the best place to add the import
    final lines = content.split('\n');
    int importIndex = 0;

    // Find last import or first non-comment line
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('import ') || line.startsWith('export ')) {
        importIndex = i + 1;
      } else if (line.isNotEmpty &&
          !line.startsWith('//') &&
          !line.startsWith('/*')) {
        break;
      }
    }

    lines.insert(importIndex, "import 'package:nx_di/nx_di.dart';");
    return lines.join('\n');
  }

  /// Print migration summary
  void _printSummary() {
    print('\n📊 Migration Summary:');
    print('Files processed: ${stats.filesProcessed}');
    print('Files modified: ${stats.filesModified}');
    print('Imports replaced: ${stats.importsReplaced}');
    print('Instances replaced: ${stats.instancesReplaced}');
    print('Methods replaced: ${stats.methodsReplaced}');

    if (stats.modifiedFiles.isNotEmpty) {
      print('\n📝 Modified files:');
      for (final file in stats.modifiedFiles) {
        print('  - $file');
      }
    }

    if (stats.errors.isNotEmpty) {
      print('\n❌ Errors:');
      for (final error in stats.errors) {
        print('  - $error');
      }
    }

    if (config.dryRun) {
      print('\n🔍 This was a dry run - no files were actually modified.');
      print('Run without --dry-run flag to apply changes.');
    } else if (config.createBackup && stats.filesModified > 0) {
      print('\n💾 Backup files created with .backup extension');
    }

    print('\n🎉 Migration completed successfully!');
    print('\nNext steps:');
    print('1. Review the modified files');
    print('2. Run your tests to ensure everything works');
    print('3. Look for any TODO comments for manual fixes needed');
    print('4. Consider using nx-di profiles for better organization');
  }
}
