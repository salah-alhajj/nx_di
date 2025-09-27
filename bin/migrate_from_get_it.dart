#!/usr/bin/env dart
// bin/migrate_from_get_it.dart

import 'dart:io';
import 'package:args/args.dart';
import 'package:nx_di/src/migration/get_it_migrator.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'path',
      abbr: 'p',
      defaultsTo: '.',
      help: 'Root path to process (default: current directory)',
    )
    ..addFlag(
      'dry-run',
      abbr: 'd',
      defaultsTo: false,
      help: 'Show what would be changed without making modifications',
    )
    ..addFlag(
      'backup',
      abbr: 'b',
      defaultsTo: true,
      help: 'Create backup files (default: true)',
    )
    ..addFlag(
      'remove-get-it',
      abbr: 'r',
      defaultsTo: true,
      help: 'Remove get_it imports after migration (default: true)',
    )
    ..addOption(
      'instance-name',
      abbr: 'i',
      defaultsTo: 'nx',
      help: 'Global instance name (default: nx)',
    )
    ..addMultiOption(
      'include',
      help: 'File patterns to include (default: **/*.dart)',
    )
    ..addMultiOption('exclude', help: 'File patterns to exclude')
    ..addFlag('help', abbr: 'h', help: 'Show this help message')
    ..addFlag('verbose', abbr: 'v', help: 'Show verbose output');

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _showHelp(parser);
      return;
    }

    if (kDebugMode) {
      print('🚀 nx-di Migration Tool');
      print('━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    final migrator = GetItMigrator();

    // Configure the migrator
    migrator.config = migrator.migrationConfig(
      rootPath: results['path'] as String,
      includePatterns: results['include'].isEmpty
          ? ['**/*.dart']
          : results['include'] as List<String>,
      excludePatterns: results['exclude'] as List<String>,
      createBackup: results['backup'] as bool,
      globalInstanceName: results['instance-name'] as String,
      addNxDiImport: true,
      removeGetItImport: results['remove-get-it'] as bool,
      dryRun: results['dry-run'] as bool,
    );

    if (results['dry-run'] as bool && kDebugMode) {
      print('🔍 Running in DRY-RUN mode - no files will be modified');
    }

    if (results['verbose'] as bool && kDebugMode) {
      print('Configuration:');
      print('  Root path: ${migrator.config.rootPath}');
      print('  Include patterns: ${migrator.config.includePatterns}');
      print('  Exclude patterns: ${migrator.config.excludePatterns}');
      print('  Instance name: ${migrator.config.globalInstanceName}');
      print('  Create backup: ${migrator.config.createBackup}');
      print('  Remove get_it: ${migrator.config.removeGetItImport}');
      print('');
    }

    final stats = await migrator.migrate();

    if (kDebugMode) {
      print('\n✅ Migration completed!');
    }
    if (stats.errors.isNotEmpty) {
      if (kDebugMode) {
        print('\n⚠️  Errors encountered:');
        for (final error in stats.errors) {
          print('  • $error');
        }
      }
      exit(1);
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Migration failed: $e');
      print('\nUse --help for usage information');
    }
    exit(1);
  }
}

void _showHelp(ArgParser parser) {
  print('''
🚀 nx-di Migration Tool
━━━━━━━━━━━━━━━━━━━━━━━━

Automatically migrate your project from get_it to nx-di.

USAGE:
  dart run nx_di:migrate [options]

EXAMPLES:
  # Basic migration (current directory)
  dart run nx_di:migrate

  # Dry run to see what would change
  dart run nx_di:migrate --dry-run

  # Migrate specific directory without backups
  dart run nx_di:migrate --path ./lib --no-backup

  # Use custom instance name
  dart run nx_di:migrate --instance-name di

  # Exclude test files
  dart run nx_di:migrate --exclude "test/**" --exclude "**/*_test.dart"

OPTIONS:
${parser.usage}

NOTES:
  • Creates .backup files by default
  • Processes .dart files recursively
  • Skips generated files (.g.dart, .freezed.dart, etc.)
  • Replaces GetIt.instance with your chosen instance name
  • Converts get_it imports to nx_di imports
  • Handles most common get_it patterns automatically

For more information, visit: https://pub.dev/packages/nx_di
''');
}
