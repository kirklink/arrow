import '../request.dart';
import '../request_middleware.dart';

/// Rate limit state for a single key within a fixed window.
class RateLimitEntry {
  int count;
  DateTime windowStart;

  RateLimitEntry(this.count, this.windowStart);
}

/// Abstract storage backend for rate limit state.
///
/// Implement this to provide custom storage (e.g., Redis) for
/// multi-process deployments. The default [MemoryRateLimitStore]
/// is suitable for single-process servers.
abstract class RateLimitStore {
  /// Increment the hit count for [key] and return the current entry.
  /// If no entry exists or the window has expired, start a new window.
  RateLimitEntry increment(String key, Duration window);

  /// Remove expired entries to free memory.
  void cleanup(Duration window);
}

/// In-memory rate limit store using a Dart [Map].
///
/// Suitable for single-process deployments. State is lost on restart.
/// Expired entries are lazily cleaned up every [_cleanupInterval] increments.
class MemoryRateLimitStore implements RateLimitStore {
  final _entries = <String, RateLimitEntry>{};
  int _accessCount = 0;
  static const _cleanupInterval = 100;

  @override
  RateLimitEntry increment(String key, Duration window) {
    _accessCount++;
    if (_accessCount >= _cleanupInterval) {
      cleanup(window);
      _accessCount = 0;
    }

    final now = DateTime.now();
    final entry = _entries[key];

    if (entry == null || now.difference(entry.windowStart) >= window) {
      final newEntry = RateLimitEntry(1, now);
      _entries[key] = newEntry;
      return newEntry;
    }

    entry.count++;
    return entry;
  }

  @override
  void cleanup(Duration window) {
    final now = DateTime.now();
    _entries.removeWhere(
      (_, entry) => now.difference(entry.windowStart) >= window,
    );
  }
}

/// Configuration for rate limiting middleware.
///
/// ```dart
/// // 100 requests per minute (defaults)
/// router.onRequest(rateLimit());
///
/// // Custom limits
/// router.onRequest(rateLimit(RateLimitConfig(
///   maxRequests: 10,
///   window: Duration(seconds: 30),
/// )));
///
/// // Custom key extraction (e.g., by API key header)
/// router.onRequest(rateLimit(RateLimitConfig(
///   keyExtractor: (req) => req.headers.value('X-API-Key') ?? 'anonymous',
/// )));
/// ```
class RateLimitConfig {
  /// Maximum requests allowed per [window]. Defaults to 100.
  final int maxRequests;

  /// Time window for the rate limit. Defaults to 1 minute.
  final Duration window;

  /// Function to extract the rate limit key from a request.
  /// Defaults to client IP address.
  ///
  /// Behind a reverse proxy, use `X-Forwarded-For`:
  /// ```dart
  /// keyExtractor: (req) =>
  ///   req.headers.value('X-Forwarded-For')?.split(',').first.trim() ??
  ///   req.innerRequest.connectionInfo?.remoteAddress.address ??
  ///   'unknown',
  /// ```
  final String Function(Request req)? keyExtractor;

  /// Message returned in the 429 response body.
  final String message;

  /// Whether to include `X-RateLimit-*` headers on every response.
  /// Defaults to `true`.
  final bool includeHeaders;

  /// Custom storage backend. Defaults to [MemoryRateLimitStore].
  final RateLimitStore? store;

  RateLimitConfig({
    this.maxRequests = 100,
    this.window = const Duration(minutes: 1),
    this.keyExtractor,
    this.message = 'Too Many Requests',
    this.includeHeaders = true,
    this.store,
  });
}

/// Rate limiting middleware using a fixed-window algorithm.
///
/// Sets standard rate limit headers on every response:
/// - `X-RateLimit-Limit` — maximum requests per window
/// - `X-RateLimit-Remaining` — remaining requests in current window
/// - `X-RateLimit-Reset` — Unix timestamp (seconds) when window resets
///
/// When the limit is exceeded, responds with 429 and adds `Retry-After`.
///
/// ```dart
/// // Global: 100 requests/minute
/// router.onRequest(rateLimit());
///
/// // Per-route: strict limit on login
/// router.post('/auth/login', loginHandler)
///   ..addOnRequest(rateLimit(RateLimitConfig(
///     maxRequests: 5,
///     window: Duration(minutes: 15),
///   )));
/// ```
RequestMiddleware rateLimit([RateLimitConfig? config]) {
  config ??= RateLimitConfig();
  final store = config.store ?? MemoryRateLimitStore();
  final maxRequests = config.maxRequests;
  final window = config.window;
  final message = config.message;
  final includeHeaders = config.includeHeaders;

  String defaultKeyExtractor(Request req) {
    return req.innerRequest.connectionInfo?.remoteAddress.address ?? 'unknown';
  }

  final extractKey = config.keyExtractor ?? defaultKeyExtractor;

  return (Request req) async {
    final key = extractKey(req);
    final entry = store.increment(key, window);

    final resetTime = entry.windowStart.add(window);
    final resetEpoch = (resetTime.millisecondsSinceEpoch / 1000).ceil();

    if (includeHeaders) {
      final headers = req.innerRequest.response.headers;
      headers.set('X-RateLimit-Limit', maxRequests.toString());
      final remaining = maxRequests - entry.count;
      headers.set(
          'X-RateLimit-Remaining', (remaining < 0 ? 0 : remaining).toString());
      headers.set('X-RateLimit-Reset', resetEpoch.toString());
    }

    if (entry.count > maxRequests) {
      final retryAfter = resetTime.difference(DateTime.now()).inSeconds;
      req.innerRequest.response.headers
          .set('Retry-After', (retryAfter < 1 ? 1 : retryAfter).toString());
      req.respond.tooManyRequests(msg: message);
      return req;
    }

    return req;
  };
}
