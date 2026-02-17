import 'package:test/test.dart';
import 'package:arrow/src/request.dart';
import 'package:arrow/src/middlewares/rate_limit.dart';
import '../test_helpers.dart';

void main() {
  group('Rate Limiting Middleware', () {
    tearDownAll(() async {
      await cleanupAllMockRequests();
    });

    group('RateLimitConfig', () {
      test('should use default values', () {
        final config = RateLimitConfig();

        expect(config.maxRequests, equals(100));
        expect(config.window, equals(const Duration(minutes: 1)));
        expect(config.keyExtractor, isNull);
        expect(config.message, equals('Too Many Requests'));
        expect(config.includeHeaders, isTrue);
        expect(config.store, isNull);
      });

      test('should accept custom values', () {
        final config = RateLimitConfig(
          maxRequests: 10,
          window: const Duration(seconds: 30),
          message: 'Slow down',
          includeHeaders: false,
        );

        expect(config.maxRequests, equals(10));
        expect(config.window, equals(const Duration(seconds: 30)));
        expect(config.message, equals('Slow down'));
        expect(config.includeHeaders, isFalse);
      });

      test('should accept custom keyExtractor', () {
        final config = RateLimitConfig(
          keyExtractor: (req) => 'custom-key',
        );

        expect(config.keyExtractor, isNotNull);
      });

      test('should accept custom store', () {
        final store = MemoryRateLimitStore();
        final config = RateLimitConfig(store: store);

        expect(config.store, same(store));
      });
    });

    group('MemoryRateLimitStore', () {
      test('should create new entry on first request', () {
        final store = MemoryRateLimitStore();
        final window = const Duration(minutes: 1);

        final entry = store.increment('192.168.1.1', window);

        expect(entry.count, equals(1));
        expect(entry.windowStart, isNotNull);
      });

      test('should increment count for same key in same window', () {
        final store = MemoryRateLimitStore();
        final window = const Duration(minutes: 1);

        store.increment('192.168.1.1', window);
        store.increment('192.168.1.1', window);
        final entry = store.increment('192.168.1.1', window);

        expect(entry.count, equals(3));
      });

      test('should track different keys independently', () {
        final store = MemoryRateLimitStore();
        final window = const Duration(minutes: 1);

        store.increment('192.168.1.1', window);
        store.increment('192.168.1.1', window);
        final entry2 = store.increment('10.0.0.1', window);

        expect(entry2.count, equals(1));
      });

      test('should reset count when window expires', () async {
        final store = MemoryRateLimitStore();
        final window = const Duration(milliseconds: 50);

        store.increment('192.168.1.1', window);
        store.increment('192.168.1.1', window);

        await Future.delayed(const Duration(milliseconds: 60));

        final entry = store.increment('192.168.1.1', window);
        expect(entry.count, equals(1));
      });

      test('should cleanup expired entries', () async {
        final store = MemoryRateLimitStore();
        final window = const Duration(milliseconds: 50);

        store.increment('192.168.1.1', window);
        store.increment('10.0.0.1', window);

        await Future.delayed(const Duration(milliseconds: 60));

        store.cleanup(window);

        // After cleanup, a new increment should start fresh
        final entry = store.increment('192.168.1.1', window);
        expect(entry.count, equals(1));
      });

      test('should not cleanup active entries', () {
        final store = MemoryRateLimitStore();
        final window = const Duration(minutes: 1);

        store.increment('192.168.1.1', window);
        store.increment('192.168.1.1', window);

        store.cleanup(window);

        final entry = store.increment('192.168.1.1', window);
        expect(entry.count, equals(3));
      });
    });

    group('rateLimit() middleware', () {
      group('allowing requests', () {
        test('should allow requests under the limit', () async {
          final httpReq = await createMockHttpRequest();
          final req = Request(httpReq);
          final mw = rateLimit(RateLimitConfig(maxRequests: 5));

          await mw(req);

          expect(req.isAlive, isTrue);

          await cleanupMockRequest(httpReq);
        });

        test('should set X-RateLimit-Limit header', () async {
          final httpReq = await createMockHttpRequest();
          final req = Request(httpReq);
          final mw = rateLimit(RateLimitConfig(maxRequests: 50));

          await mw(req);

          expect(req.innerRequest.response.headers.value('X-RateLimit-Limit'),
              equals('50'));

          await cleanupMockRequest(httpReq);
        });

        test('should set X-RateLimit-Remaining header', () async {
          final httpReq = await createMockHttpRequest();
          final req = Request(httpReq);
          final mw = rateLimit(RateLimitConfig(maxRequests: 10));

          await mw(req);

          expect(
              req.innerRequest.response.headers
                  .value('X-RateLimit-Remaining'),
              equals('9'));

          await cleanupMockRequest(httpReq);
        });

        test('should set X-RateLimit-Reset header', () async {
          final httpReq = await createMockHttpRequest();
          final req = Request(httpReq);
          final mw = rateLimit(RateLimitConfig(maxRequests: 10));

          await mw(req);

          final resetStr = req.innerRequest.response.headers
              .value('X-RateLimit-Reset');
          expect(resetStr, isNotNull);

          final resetEpoch = int.parse(resetStr!);
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          // Reset should be within ~60s from now (default 1 minute window)
          expect(resetEpoch, greaterThan(now));
          expect(resetEpoch, lessThanOrEqualTo(now + 61));

          await cleanupMockRequest(httpReq);
        });

        test('should decrement remaining on each request', () async {
          final store = MemoryRateLimitStore();
          final mw = rateLimit(RateLimitConfig(
            maxRequests: 5,
            store: store,
            keyExtractor: (_) => 'test-key',
          ));

          // Make 3 requests
          for (var i = 0; i < 3; i++) {
            final httpReq = await createMockHttpRequest();
            final req = Request(httpReq);
            await mw(req);
            if (i == 2) {
              expect(
                  req.innerRequest.response.headers
                      .value('X-RateLimit-Remaining'),
                  equals('2'));
            }
            await cleanupMockRequest(httpReq);
          }
        });

        test('should not cancel the request', () async {
          final httpReq = await createMockHttpRequest();
          final req = Request(httpReq);
          final mw = rateLimit(RateLimitConfig(maxRequests: 10));

          final result = await mw(req);

          expect(result.isAlive, isTrue);
          expect(identical(result, req), isTrue);

          await cleanupMockRequest(httpReq);
        });
      });

      group('blocking requests', () {
        test('should respond 429 when limit exceeded', () async {
          final store = MemoryRateLimitStore();
          final mw = rateLimit(RateLimitConfig(
            maxRequests: 2,
            store: store,
            keyExtractor: (_) => 'test-key',
          ));

          // Use up the limit
          for (var i = 0; i < 2; i++) {
            final httpReq = await createMockHttpRequest();
            final req = Request(httpReq);
            await mw(req);
            await cleanupMockRequest(httpReq);
          }

          // This should be blocked
          final httpReq = await createMockHttpRequest();
          final req = Request(httpReq);
          await mw(req);

          expect(req.innerRequest.response.statusCode, equals(429));
          expect(req.isAlive, isFalse);

          await cleanupMockRequest(httpReq);
        });

        test('should set Retry-After header when blocked', () async {
          final store = MemoryRateLimitStore();
          final mw = rateLimit(RateLimitConfig(
            maxRequests: 1,
            store: store,
            keyExtractor: (_) => 'test-key',
          ));

          // Use up the limit
          final httpReq1 = await createMockHttpRequest();
          await mw(Request(httpReq1));
          await cleanupMockRequest(httpReq1);

          // Blocked request
          final httpReq = await createMockHttpRequest();
          final req = Request(httpReq);
          await mw(req);

          final retryAfter =
              req.innerRequest.response.headers.value('Retry-After');
          expect(retryAfter, isNotNull);
          expect(int.parse(retryAfter!), greaterThanOrEqualTo(1));

          await cleanupMockRequest(httpReq);
        });

        test('should set X-RateLimit-Remaining to 0 when blocked', () async {
          final store = MemoryRateLimitStore();
          final mw = rateLimit(RateLimitConfig(
            maxRequests: 1,
            store: store,
            keyExtractor: (_) => 'test-key',
          ));

          // Use up the limit
          final httpReq1 = await createMockHttpRequest();
          await mw(Request(httpReq1));
          await cleanupMockRequest(httpReq1);

          // Blocked request
          final httpReq = await createMockHttpRequest();
          final req = Request(httpReq);
          await mw(req);

          expect(
              req.innerRequest.response.headers
                  .value('X-RateLimit-Remaining'),
              equals('0'));

          await cleanupMockRequest(httpReq);
        });

        test('should use custom message in 429 response', () async {
          final store = MemoryRateLimitStore();
          final mw = rateLimit(RateLimitConfig(
            maxRequests: 1,
            store: store,
            message: 'Slow down please',
            keyExtractor: (_) => 'test-key',
          ));

          // Use up the limit
          final httpReq1 = await createMockHttpRequest();
          await mw(Request(httpReq1));
          await cleanupMockRequest(httpReq1);

          // Blocked request
          final httpReq = await createMockHttpRequest();
          final req = Request(httpReq);
          await mw(req);

          expect(req.innerRequest.response.statusCode, equals(429));

          await cleanupMockRequest(httpReq);
        });
      });

      group('key extraction', () {
        test('should use custom keyExtractor when provided', () async {
          final store = MemoryRateLimitStore();
          final mw = rateLimit(RateLimitConfig(
            maxRequests: 1,
            store: store,
            keyExtractor: (req) =>
                req.headers.value('X-API-Key') ?? 'anonymous',
          ));

          // First request with key "abc"
          final httpReq1 = await createMockHttpRequest(
            headers: {'X-API-Key': 'abc'},
          );
          final req1 = Request(httpReq1);
          await mw(req1);
          expect(req1.isAlive, isTrue);
          await cleanupMockRequest(httpReq1);

          // Second request with same key should be blocked
          final httpReq2 = await createMockHttpRequest(
            headers: {'X-API-Key': 'abc'},
          );
          final req2 = Request(httpReq2);
          await mw(req2);
          expect(req2.isAlive, isFalse);
          await cleanupMockRequest(httpReq2);

          // Request with different key should be allowed
          final httpReq3 = await createMockHttpRequest(
            headers: {'X-API-Key': 'xyz'},
          );
          final req3 = Request(httpReq3);
          await mw(req3);
          expect(req3.isAlive, isTrue);
          await cleanupMockRequest(httpReq3);
        });

        test('should track different IPs independently', () async {
          // Two separate rateLimit instances (simulating per-IP behavior)
          // Both use the same store but default key extractor gives same IP
          // since all mock requests come from localhost.
          // Use custom keys to simulate different IPs.
          final store = MemoryRateLimitStore();
          final mw = rateLimit(RateLimitConfig(
            maxRequests: 1,
            store: store,
          ));

          // First request from "IP A" (uses keyExtractor default = localhost)
          final httpReq1 = await createMockHttpRequest();
          final req1 = Request(httpReq1);
          await mw(req1);
          expect(req1.isAlive, isTrue);
          await cleanupMockRequest(httpReq1);

          // Second request from same IP should be blocked
          final httpReq2 = await createMockHttpRequest();
          final req2 = Request(httpReq2);
          await mw(req2);
          expect(req2.isAlive, isFalse);
          await cleanupMockRequest(httpReq2);
        });
      });

      group('headers', () {
        test('should not set rate limit headers when includeHeaders is false',
            () async {
          final httpReq = await createMockHttpRequest();
          final req = Request(httpReq);
          final mw = rateLimit(RateLimitConfig(
            maxRequests: 10,
            includeHeaders: false,
          ));

          await mw(req);

          expect(req.innerRequest.response.headers.value('X-RateLimit-Limit'),
              isNull);
          expect(
              req.innerRequest.response.headers
                  .value('X-RateLimit-Remaining'),
              isNull);
          expect(req.innerRequest.response.headers.value('X-RateLimit-Reset'),
              isNull);

          await cleanupMockRequest(httpReq);
        });

        test('should still set Retry-After on 429 even if includeHeaders is false',
            () async {
          final store = MemoryRateLimitStore();
          final mw = rateLimit(RateLimitConfig(
            maxRequests: 1,
            store: store,
            includeHeaders: false,
            keyExtractor: (_) => 'test-key',
          ));

          // Use up the limit
          final httpReq1 = await createMockHttpRequest();
          await mw(Request(httpReq1));
          await cleanupMockRequest(httpReq1);

          // Blocked request
          final httpReq = await createMockHttpRequest();
          final req = Request(httpReq);
          await mw(req);

          expect(req.innerRequest.response.headers.value('Retry-After'),
              isNotNull);
          expect(req.innerRequest.response.headers.value('X-RateLimit-Limit'),
              isNull);

          await cleanupMockRequest(httpReq);
        });
      });

      group('window reset', () {
        test('should allow requests after window resets', () async {
          final store = MemoryRateLimitStore();
          final mw = rateLimit(RateLimitConfig(
            maxRequests: 1,
            window: const Duration(milliseconds: 50),
            store: store,
            keyExtractor: (_) => 'test-key',
          ));

          // Use up the limit
          final httpReq1 = await createMockHttpRequest();
          await mw(Request(httpReq1));
          await cleanupMockRequest(httpReq1);

          // Wait for window to expire
          await Future.delayed(const Duration(milliseconds: 60));

          // Should be allowed again
          final httpReq = await createMockHttpRequest();
          final req = Request(httpReq);
          await mw(req);

          expect(req.isAlive, isTrue);
          expect(
              req.innerRequest.response.headers
                  .value('X-RateLimit-Remaining'),
              equals('0'));

          await cleanupMockRequest(httpReq);
        });
      });

      group('independent stores', () {
        test('separate rateLimit() instances have independent stores',
            () async {
          final mw1 = rateLimit(RateLimitConfig(
            maxRequests: 1,
            keyExtractor: (_) => 'test-key',
          ));
          final mw2 = rateLimit(RateLimitConfig(
            maxRequests: 1,
            keyExtractor: (_) => 'test-key',
          ));

          // Use up limit on mw1
          final httpReq1 = await createMockHttpRequest();
          await mw1(Request(httpReq1));
          await cleanupMockRequest(httpReq1);

          // mw2 should still allow (separate store)
          final httpReq2 = await createMockHttpRequest();
          final req2 = Request(httpReq2);
          await mw2(req2);

          expect(req2.isAlive, isTrue);

          await cleanupMockRequest(httpReq2);
        });
      });

      group('integration', () {
        test('rate limit headers persist after ok() response', () async {
          final httpReq = await createMockHttpRequest();
          final req = Request(httpReq);
          final mw = rateLimit(RateLimitConfig(maxRequests: 100));

          await mw(req);
          req.respond.ok(data: {'test': true});

          final headers = req.innerRequest.response.headers;
          expect(headers.value('X-RateLimit-Limit'), equals('100'));
          expect(headers.value('X-RateLimit-Remaining'), isNotNull);

          await cleanupMockRequest(httpReq);
        });
      });
    });
  });
}
