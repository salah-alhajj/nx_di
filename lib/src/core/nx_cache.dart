// src/core/nx_cache.dart

import 'dart:collection';

/// Fast service key for reduced overhead
class FastServiceKey {
  final Type type;
  final String? instanceName;
  final int _hashCode;

  FastServiceKey(this.type, this.instanceName)
    : _hashCode = Object.hash(type, instanceName);

  @override
  bool operator ==(Object other) =>
      other is FastServiceKey &&
      type == other.type &&
      instanceName == other.instanceName;

  @override
  int get hashCode => _hashCode;
}

/// Cache entry for dependency resolution
class NxCacheEntry<T extends Object> {
  /// The cached instance
  final T instance;

  /// When this entry was created
  final int createdAt; // Store as ms since epoch for performance

  /// Number of times this entry has been accessed
  int accessCount = 0;

  /// Last access time
  int lastAccessedAt; // Store as ms since epoch

  NxCacheEntry(this.instance)
    : createdAt = DateTime.now().millisecondsSinceEpoch,
      lastAccessedAt = DateTime.now().millisecondsSinceEpoch;

  /// Update access statistics
  void recordAccess() {
    accessCount++;
    lastAccessedAt = DateTime.now().millisecondsSinceEpoch;
  }

  /// Age of this cache entry in milliseconds
  int get ageMs => DateTime.now().millisecondsSinceEpoch - createdAt;

  /// Time since last access in milliseconds
  int get timeSinceLastAccessMs =>
      DateTime.now().millisecondsSinceEpoch - lastAccessedAt;
}

/// LRU cache for dependency resolution
class NxResolutionCache {
  /// Maximum cache size
  final int maxSize;

  /// Cache entries using LinkedHashMap for O(1) LRU
  final LinkedHashMap<FastServiceKey, NxCacheEntry> _cache =
      LinkedHashMap<FastServiceKey, NxCacheEntry>();

  NxResolutionCache({this.maxSize = 1000});

  /// Get cache key for type and instance name
  FastServiceKey _getCacheKey<T extends Object>({String? instanceName}) {
    return FastServiceKey(T, instanceName);
  }

  /// Check if an entry exists in cache
  bool contains<T extends Object>({String? instanceName}) {
    final key = _getCacheKey<T>(instanceName: instanceName);
    return _cache.containsKey(key);
  }

  /// Get cached entry
  T? get<T extends Object>({String? instanceName}) {
    final key = _getCacheKey<T>(instanceName: instanceName);
    final entry = _cache.remove(key); // Remove and re-insert for LRU

    if (entry != null) {
      // Update access statistics
      entry.recordAccess();
      _cache[key] = entry; // Re-insert to mark as most recently used
      return entry.instance as T;
    }

    return null;
  }

  /// Put entry in cache
  void put<T extends Object>(T instance, {String? instanceName}) {
    final key = _getCacheKey<T>(instanceName: instanceName);

    // Remove old entry if it exists to update its position
    _cache.remove(key);

    // Add new entry
    _cache[key] = NxCacheEntry<T>(instance);

    // Evict if over capacity
    if (_cache.length > maxSize) {
      _cache.remove(_cache.keys.first); // Remove the least recently used
    }
  }

  /// Remove entry from cache
  bool remove<T extends Object>({String? instanceName}) {
    final key = _getCacheKey<T>(instanceName: instanceName);
    return _cache.remove(key) != null;
  }

  /// Clear all cache entries
  void clear() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final totalAccesses = _cache.values.fold<int>(
      0,
      (sum, entry) => sum + entry.accessCount,
    );

    final averageAccesses = _cache.isNotEmpty
        ? totalAccesses / _cache.length
        : 0.0;

    return {
      'size': _cache.length,
      'max_size': maxSize,
      'total_accesses': totalAccesses,
      'average_accesses_per_entry': averageAccesses,
      'hit_rate': 0.0, // This would be tracked by the consumer
    };
  }

  /// Get cache entries sorted by access count (for debugging)
  List<MapEntry<FastServiceKey, NxCacheEntry>> getMostAccessedEntries([
    int limit = 10,
  ]) {
    final entries = _cache.entries.toList();
    entries.sort((a, b) => b.value.accessCount.compareTo(a.value.accessCount));
    return entries.take(limit).toList();
  }

  /// Get cache utilization as a percentage
  double get utilizationPercent => (_cache.length / maxSize) * 100;

  /// Whether cache is at capacity
  bool get isAtCapacity => _cache.length >= maxSize;
}

/// Cache manager for different cache types
class NxCacheManager {
  /// Resolution cache
  NxResolutionCache? _resolutionCache;

  /// Whether caching is enabled
  bool _cachingEnabled = false;

  /// Cache hit/miss statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;

  /// Enable caching with specified cache size
  void enableCaching({int maxCacheSize = 1000}) {
    _cachingEnabled = true;
    _resolutionCache = NxResolutionCache(maxSize: maxCacheSize);
  }

  /// Disable caching and clear all cached entries
  void disableCaching() {
    _cachingEnabled = false;
    _resolutionCache?.clear();
    _resolutionCache = null;
  }

  /// Check if caching is enabled
  bool get isCachingEnabled => _cachingEnabled;

  /// Try to get cached instance
  T? getCached<T extends Object>({String? instanceName}) {
    if (!_cachingEnabled || _resolutionCache == null) return null;

    final cached = _resolutionCache!.get<T>(instanceName: instanceName);
    if (cached != null) {
      _cacheHits++;
      return cached;
    } else {
      _cacheMisses++;
      return null;
    }
  }

  /// Cache an instance
  void cache<T extends Object>(T instance, {String? instanceName}) {
    if (!_cachingEnabled || _resolutionCache == null) return;
    _resolutionCache!.put<T>(instance, instanceName: instanceName);
  }

  /// Remove cached instance
  bool removeCached<T extends Object>({String? instanceName}) {
    if (!_cachingEnabled || _resolutionCache == null) return false;
    return _resolutionCache!.remove<T>(instanceName: instanceName);
  }

  /// Clear all cached instances
  void clearCache() {
    _resolutionCache?.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final totalOperations = _cacheHits + _cacheMisses;
    final hitRate = totalOperations > 0 ? _cacheHits / totalOperations : 0.0;

    final resolutionStats = _resolutionCache?.getStats() ?? {};

    return {
      'enabled': _cachingEnabled,
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'hit_rate': hitRate,
      'resolution_cache': resolutionStats,
    };
  }
}
