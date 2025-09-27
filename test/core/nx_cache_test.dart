import 'package:test/test.dart';
import 'package:nx_di/src/core/nx_cache.dart';

class ServiceA {}

class ServiceB {}

void main() {
  group('NxResolutionCache', () {
    late NxResolutionCache cache;

    setUp(() {
      cache = NxResolutionCache(maxSize: 3);
    });

    test('put and get works correctly', () {
      final serviceA = ServiceA();
      cache.put(serviceA);

      final retrieved = cache.get<ServiceA>();
      expect(retrieved, same(serviceA));
    });

    test('contains returns correct status', () {
      final serviceA = ServiceA();
      cache.put(serviceA);

      expect(cache.contains<ServiceA>(), isTrue);
      expect(cache.contains<ServiceB>(), isFalse);
    });

    test('remove works correctly', () {
      final serviceA = ServiceA();
      cache.put(serviceA);

      expect(cache.contains<ServiceA>(), isTrue);

      final removed = cache.remove<ServiceA>();
      expect(removed, isTrue);
      expect(cache.contains<ServiceA>(), isFalse);
    });

    test('clear removes all entries', () {
      cache.put(ServiceA());
      cache.put(ServiceB());

      expect(cache.contains<ServiceA>(), isTrue);
      expect(cache.contains<ServiceB>(), isTrue);

      cache.clear();

      expect(cache.contains<ServiceA>(), isFalse);
      expect(cache.contains<ServiceB>(), isFalse);
    });

    test('LRU eviction works correctly', () {
      final service1 = ServiceA();
      final service2 = ServiceB();
      final service3 = ServiceA(); // Different instance
      final service4 = ServiceB(); // Different instance

      cache.put(service1);
      cache.put(service2, instanceName: 'b1');
      cache.put(service3, instanceName: 'a2');

      // Access service1 to make it most recently used
      cache.get<ServiceA>();

      cache.put(service4, instanceName: 'b2');

      expect(cache.contains<ServiceA>(), isTrue);
      expect(
        cache.contains<ServiceB>(instanceName: 'b1'),
        isFalse,
      ); // Should be evicted
      expect(cache.contains<ServiceA>(instanceName: 'a2'), isTrue);
      expect(cache.contains<ServiceB>(instanceName: 'b2'), isTrue);
    });

    test('getStats returns correct statistics', () {
      cache.put(ServiceA());
      cache.put(ServiceB());

      cache.get<ServiceA>();
      cache.get<ServiceA>();
      cache.get<ServiceB>();

      final stats = cache.getStats();
      expect(stats['size'], 2);
      expect(stats['max_size'], 3);
      expect(stats['total_accesses'], 3);
      expect(stats['average_accesses_per_entry'], 1.5);
    });
  });

  group('NxCacheManager', () {
    late NxCacheManager manager;

    setUp(() {
      manager = NxCacheManager();
    });

    test('caching is disabled by default', () {
      expect(manager.isCachingEnabled, isFalse);
    });

    test('enableCaching enables caching and creates a resolution cache', () {
      manager.enableCaching(maxCacheSize: 5);
      expect(manager.isCachingEnabled, isTrue);

      final stats = manager.getStats();
      expect(stats['enabled'], isTrue);
      expect(stats['resolution_cache']['max_size'], 5);
    });

    test('disableCaching disables and clears the cache', () {
      manager.enableCaching();
      manager.cache(ServiceA());

      manager.disableCaching();

      expect(manager.isCachingEnabled, isFalse);
      final stats = manager.getStats();
      expect(stats['resolution_cache'], isEmpty);
    });

    test('getCached returns null when caching is disabled', () {
      final result = manager.getCached<ServiceA>();
      expect(result, isNull);
    });

    test('getCached returns cached instance and updates stats', () {
      manager.enableCaching();
      final serviceA = ServiceA();
      manager.cache(serviceA);

      final retrieved = manager.getCached<ServiceA>();
      expect(retrieved, same(serviceA));

      final stats = manager.getStats();
      expect(stats['cache_hits'], 1);
      expect(stats['cache_misses'], 0);
      expect(stats['hit_rate'], 1.0);
    });

    test('getCached returns null for miss and updates stats', () {
      manager.enableCaching();

      final retrieved = manager.getCached<ServiceA>();
      expect(retrieved, isNull);

      final stats = manager.getStats();
      expect(stats['cache_hits'], 0);
      expect(stats['cache_misses'], 1);
      expect(stats['hit_rate'], 0.0);
    });

    test('clearCache clears cache and resets stats', () {
      manager.enableCaching();
      manager.cache(ServiceA());
      manager.getCached<ServiceA>();

      manager.clearCache();

      final stats = manager.getStats();
      expect(stats['cache_hits'], 0);
      expect(stats['cache_misses'], 0);
      expect(stats['hit_rate'], 0.0);
      expect(stats['resolution_cache']['size'], 0);
    });
  });
}
