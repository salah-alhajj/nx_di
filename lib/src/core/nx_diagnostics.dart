// src/core/nx_diagnostics.dart

/// Diagnostic information about NxLocator state
class NxDiagnosticInfo {
  /// Total number of registered services across all profiles
  final int totalServices;

  /// Number of active profiles
  final int activeProfiles;

  /// Number of cached resolutions
  final int cachedResolutions;

  /// Total memory usage estimate in bytes
  final int estimatedMemoryUsage;

  /// Performance statistics
  final NxPerformanceStats performanceStats;

  /// Configuration issues found
  final List<NxDiagnosticIssue> configurationIssues;

  /// Performance warnings
  final List<NxDiagnosticIssue> performanceWarnings;

  /// Dependency graph health
  final NxGraphHealth graphHealth;

  const NxDiagnosticInfo({
    required this.totalServices,
    required this.activeProfiles,
    required this.cachedResolutions,
    required this.estimatedMemoryUsage,
    required this.performanceStats,
    required this.configurationIssues,
    required this.performanceWarnings,
    required this.graphHealth,
  });

  /// Whether the locator is in a healthy state
  bool get isHealthy =>
      configurationIssues.isEmpty &&
      performanceWarnings
          .where((w) => w.severity == DiagnosticSeverity.error)
          .isEmpty &&
      graphHealth.isHealthy;

  /// Get all issues sorted by severity
  List<NxDiagnosticIssue> get allIssues {
    final issues = [...configurationIssues, ...performanceWarnings];
    issues.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return issues;
  }
}

/// Performance statistics for NxLocator
class NxPerformanceStats {
  /// Total number of dependency resolutions
  final int totalResolutions;

  /// Average resolution time in microseconds
  final double averageResolutionTimeUs;

  /// Slowest resolution time in microseconds
  final int slowestResolutionTimeUs;

  /// Type that had the slowest resolution
  final Type? slowestResolutionType;

  /// Cache hit rate (0.0 to 1.0)
  final double cacheHitRate;

  /// Number of circular dependency checks performed
  final int circularDependencyChecks;

  /// Time spent on validation in microseconds
  final int totalValidationTimeUs;

  /// Profile activation/deactivation count
  final int profileSwitches;

  const NxPerformanceStats({
    required this.totalResolutions,
    required this.averageResolutionTimeUs,
    required this.slowestResolutionTimeUs,
    this.slowestResolutionType,
    required this.cacheHitRate,
    required this.circularDependencyChecks,
    required this.totalValidationTimeUs,
    required this.profileSwitches,
  });

  /// Whether performance is within acceptable bounds
  bool get isPerformant {
    return averageResolutionTimeUs < 1000 && // Less than 1ms average
        slowestResolutionTimeUs < 10000 && // Less than 10ms worst case
        cacheHitRate > 0.8; // 80%+ cache hit rate
  }
}

/// Dependency graph health information
class NxGraphHealth {
  /// Whether there are any circular dependencies
  final bool hasCircularDependencies;

  /// Whether there are any orphaned services
  final bool hasOrphanedServices;

  /// Whether there are any missing dependencies
  final bool hasMissingDependencies;

  /// Dependency depth analysis
  final NxDependencyDepthAnalysis depthAnalysis;

  /// Profile dependency issues
  final List<String> profileDependencyIssues;

  const NxGraphHealth({
    required this.hasCircularDependencies,
    required this.hasOrphanedServices,
    required this.hasMissingDependencies,
    required this.depthAnalysis,
    required this.profileDependencyIssues,
  });

  /// Whether the dependency graph is healthy
  bool get isHealthy =>
      !hasCircularDependencies &&
      !hasMissingDependencies &&
      profileDependencyIssues.isEmpty;
}

/// Analysis of dependency graph depth
class NxDependencyDepthAnalysis {
  /// Maximum dependency depth found
  final int maxDepth;

  /// Average dependency depth
  final double averageDepth;

  /// Services with the deepest dependency chains
  final Map<Type, int> deepestServices;

  const NxDependencyDepthAnalysis({
    required this.maxDepth,
    required this.averageDepth,
    required this.deepestServices,
  });

  /// Whether dependency depth is reasonable
  bool get isReasonable => maxDepth <= 10 && averageDepth <= 3.0;
}

/// Diagnostic issue found during analysis
class NxDiagnosticIssue {
  /// Severity of the issue
  final DiagnosticSeverity severity;

  /// Category of the issue
  final DiagnosticCategory category;

  /// Human-readable description
  final String description;

  /// Suggested fix (if available)
  final String? suggestedFix;

  /// Type or profile related to this issue
  final String? relatedComponent;

  /// Code to identify the specific issue type
  final String issueCode;

  const NxDiagnosticIssue({
    required this.severity,
    required this.category,
    required this.description,
    this.suggestedFix,
    this.relatedComponent,
    required this.issueCode,
  });

  @override
  String toString() =>
      '[$severity] $category: $description'
      '${relatedComponent != null ? ' (Related: $relatedComponent)' : ''}';
}

/// Severity levels for diagnostic issues
enum DiagnosticSeverity {
  /// Informational message
  info,

  /// Warning that should be addressed
  warning,

  /// Error that needs immediate attention
  error,

  /// Critical error that may cause application failure
  critical,
}

/// Categories of diagnostic issues
enum DiagnosticCategory {
  /// Configuration-related issues
  configuration,

  /// Performance-related issues
  performance,

  /// Dependency graph issues
  dependencies,

  /// Memory usage issues
  memory,

  /// Profile management issues
  profiles,

  /// Validation issues
  validation,
}

/// Advanced diagnostics engine for NxLocator
class NxDiagnostics {
  /// Resolution time tracking
  final Map<Type, List<int>> _resolutionTimes = {};

  /// Cache statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;

  /// Validation statistics
  int _validationTimeUs = 0;
  int _circularChecks = 0;

  /// Profile operation tracking
  int _profileSwitches = 0;

  /// Record a dependency resolution
  void recordResolution(Type type, int timeUs) {
    _resolutionTimes.putIfAbsent(type, () => []).add(timeUs);
  }

  /// Record a cache hit
  void recordCacheHit() => _cacheHits++;

  /// Record a cache miss
  void recordCacheMiss() => _cacheMisses++;

  /// Record validation time
  void recordValidationTime(int timeUs) => _validationTimeUs += timeUs;

  /// Record circular dependency check
  void recordCircularCheck() => _circularChecks++;

  /// Record profile switch
  void recordProfileSwitch() => _profileSwitches++;

  /// Generate performance statistics
  NxPerformanceStats generatePerformanceStats() {
    final allTimes = _resolutionTimes.values.expand((times) => times).toList();
    final totalResolutions = allTimes.length;

    if (totalResolutions == 0) {
      return const NxPerformanceStats(
        totalResolutions: 0,
        averageResolutionTimeUs: 0.0,
        slowestResolutionTimeUs: 0,
        cacheHitRate: 0.0,
        circularDependencyChecks: 0,
        totalValidationTimeUs: 0,
        profileSwitches: 0,
      );
    }

    final averageTime = allTimes.reduce((a, b) => a + b) / totalResolutions;
    final slowestTime = allTimes.reduce((a, b) => a > b ? a : b);

    // Find the type with the slowest resolution
    Type? slowestType;
    int slowestTypeTime = 0;
    for (final entry in _resolutionTimes.entries) {
      final maxTime = entry.value.reduce((a, b) => a > b ? a : b);
      if (maxTime > slowestTypeTime) {
        slowestTypeTime = maxTime;
        slowestType = entry.key;
      }
    }

    final totalCacheOperations = _cacheHits + _cacheMisses;
    final cacheHitRate = totalCacheOperations > 0
        ? _cacheHits / totalCacheOperations
        : 0.0;

    return NxPerformanceStats(
      totalResolutions: totalResolutions,
      averageResolutionTimeUs: averageTime,
      slowestResolutionTimeUs: slowestTime,
      slowestResolutionType: slowestType,
      cacheHitRate: cacheHitRate,
      circularDependencyChecks: _circularChecks,
      totalValidationTimeUs: _validationTimeUs,
      profileSwitches: _profileSwitches,
    );
  }

  /// Reset all statistics
  void reset() {
    _resolutionTimes.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    _validationTimeUs = 0;
    _circularChecks = 0;
    _profileSwitches = 0;
  }

  /// Generate recommendations based on performance data
  List<NxDiagnosticIssue> generateRecommendations() {
    final issues = <NxDiagnosticIssue>[];
    final stats = generatePerformanceStats();

    // Check average resolution time
    if (stats.averageResolutionTimeUs > 1000) {
      issues.add(
        NxDiagnosticIssue(
          severity: DiagnosticSeverity.warning,
          category: DiagnosticCategory.performance,
          description:
              'Average resolution time is ${stats.averageResolutionTimeUs.toStringAsFixed(0)}μs (>1ms)',
          suggestedFix:
              'Consider enabling resolution caching or using lazy singletons',
          issueCode: 'SLOW_AVERAGE_RESOLUTION',
        ),
      );
    }

    // Check cache hit rate
    if (stats.cacheHitRate < 0.5 && stats.totalResolutions > 100) {
      issues.add(
        NxDiagnosticIssue(
          severity: DiagnosticSeverity.warning,
          category: DiagnosticCategory.performance,
          description:
              'Low cache hit rate: ${(stats.cacheHitRate * 100).toStringAsFixed(1)}%',
          suggestedFix:
              'Consider using singletons for frequently accessed services',
          issueCode: 'LOW_CACHE_HIT_RATE',
        ),
      );
    }

    // Check for extremely slow resolutions
    if (stats.slowestResolutionTimeUs > 10000) {
      issues.add(
        NxDiagnosticIssue(
          severity: DiagnosticSeverity.error,
          category: DiagnosticCategory.performance,
          description:
              'Extremely slow resolution detected: ${stats.slowestResolutionTimeUs}μs',
          relatedComponent: stats.slowestResolutionType?.toString(),
          suggestedFix:
              'Investigate factory function complexity or dependencies',
          issueCode: 'EXTREMELY_SLOW_RESOLUTION',
        ),
      );
    }

    return issues;
  }
}
