# Cookie Support Implementation Plan (Task 1.5)

**Status:** Ready for implementation
**Duration:** ~2-3 hours
**Branch:** `feature/cookie-support` from `dev`

## Overview

Add cookie reading and writing support to Arrow framework following the same patterns as existing query parameter helpers. No middleware needed — `dart:io` already handles all cookie parsing and serialization automatically.

## Context

Arrow currently has no cookie support. For REST APIs, cookies are essential for:
- Authentication tokens and session IDs
- CSRF tokens
- User preferences
- Tracking and analytics

Dart's `dart:io` library already:
- Parses incoming `Cookie` headers into `HttpRequest.cookies` (`List<Cookie>`)
- Serializes `HttpResponse.cookies` into `Set-Cookie` headers automatically

Arrow just needs convenience methods that wrap this functionality using the same patterns as the existing query parameter helpers (`queryParam()`, `queryInt()`, `queryBool()`).

## Design Decisions

### 1. No Middleware Required

Unlike the original modernization plan suggestion, cookie support does NOT need a "cookie parser middleware" because:

- `dart:io` already parses cookies automatically from the `Cookie` header
- Query parameters don't use middleware — direct getters on `Request` are more ergonomic
- Cookies are accessed frequently — middleware adds unnecessary indirection

The same pattern as `req.queryParam()` → `req.cookie()` is clearer and more consistent.

### 2. Defer Signed Cookies

Signed cookies are out of scope for this task because:

- REST APIs typically use JWT tokens in the `Authorization` header, not signed cookies
- Signed cookies are primarily a session/web-app pattern
- Adding signed cookie support requires HMAC crypto and secret key management
- Can be added later as a separate middleware if needed

For now, focus on basic cookie reading/writing for auth tokens and preferences.

### 3. Security-First Defaults

Cookie settings will default to secure values:

- `httpOnly: true` — prevents JavaScript access (XSS protection)
- `secure: false` — allows local development on HTTP (developer must explicitly set `secure: true` for production)
- `sameSite` — optional but recommended (`SameSite.strict` or `SameSite.lax`)

## Implementation

### Step 1: Test Helper Support

**File:** `arrow/test/test_helpers.dart`

Add a `cookies` parameter to `createMockHttpRequest` to allow tests to inject cookies:

```dart
Future<HttpRequest> createMockHttpRequest({
  String path = '/test',
  String method = 'GET',
  Map<String, String>? headers,
  Map<String, String>? cookies,  // NEW
  String? body,
  Duration timeout = const Duration(seconds: 5),
}) async {
  // ... existing code ...

  requestFuture.then((request) {
    // Add custom headers if provided
    if (headers != null) {
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });
    }

    // Add cookies if provided (NEW)
    if (cookies != null) {
      cookies.forEach((name, value) {
        request.cookies.add(Cookie(name, value));
      });
    }

    // ... rest unchanged ...
  });
}
```

**Why:** Using `HttpClientRequest.cookies.add()` is the correct way to set cookies on the client side. Setting a raw `Cookie` header via `headers.set()` may not work reliably with dart:io's cookie jar.

### Step 2: Cookie Reading on Request

**File:** `arrow/lib/src/request.dart`

Add after the existing query helper methods (after line 109):

```dart
// Cookie helpers.

/// Lazy-cached map of cookie names to values.
Map<String, String>? _cookieMap;

/// All cookies as a Map of name to value.
///
/// Parsed from the Cookie header by dart:io. The map is cached
/// on first access. Returns an empty map if no cookies are present.
///
/// ```dart
/// // Cookie: session=abc123; theme=dark
/// final all = req.cookies;   // {'session': 'abc123', 'theme': 'dark'}
/// ```
Map<String, String> get cookies {
  _cookieMap ??= {
    for (final cookie in innerRequest.cookies) cookie.name: cookie.value
  };
  return _cookieMap!;
}

/// Get a single cookie value by name.
///
/// Returns the cookie value for [name], or [defaultValue] if the
/// cookie is not present. Returns `null` if the cookie is missing
/// and no default is provided.
///
/// Follows the same pattern as [queryParam] for consistency.
///
/// ```dart
/// // Cookie: session=abc123; theme=dark
/// final session = req.cookie('session');                  // 'abc123'
/// final missing = req.cookie('missing');                  // null
/// final fallback = req.cookie('lang', defaultValue: 'en'); // 'en'
/// ```
String? cookie(String name, {String? defaultValue}) {
  return cookies[name] ?? defaultValue;
}
```

**Why:**
- `cookies` getter provides all cookies as a simple `Map<String, String>` (mirrors Express's `req.cookies`)
- `cookie(name)` method mirrors the `queryParam(name)` pattern exactly
- Lazy caching prevents rebuilding the map on every access
- No new imports needed — `dart:io` is already imported

### Step 3: Cookie Writing on Responder

**File:** `arrow/lib/src/responder.dart`

Add after the `error()` method, before the `_errorResponse()` helper (around line 135):

```dart
/// Set a cookie on the response.
///
/// Must be called BEFORE any terminal response method (ok, badRequest, etc.)
/// because those methods finalize the response. Cookies are added to dart:io's
/// response.cookies list, which is serialized to Set-Cookie headers when the
/// response is sent.
///
/// Options:
/// - [maxAge] - How long the cookie should live (converted to seconds)
/// - [expires] - Absolute expiration date (alternative to maxAge)
/// - [path] - Path scope (default: browser determines)
/// - [domain] - Domain scope (default: current domain)
/// - [httpOnly] - Prevent JavaScript access (default: true for security)
/// - [secure] - Only send over HTTPS (default: false to allow local dev)
/// - [sameSite] - CSRF protection (SameSite.strict, .lax, or .none)
///
/// ```dart
/// req.respond.setCookie('session', 'abc123',
///   httpOnly: true,
///   secure: true,
///   maxAge: Duration(hours: 24),
///   path: '/',
///   sameSite: io.SameSite.strict,
/// );
/// return req.respond.ok(data: {'loggedIn': true});
/// ```
void setCookie(
  String name,
  String value, {
  Duration? maxAge,
  DateTime? expires,
  String? path,
  String? domain,
  bool httpOnly = true,
  bool secure = false,
  io.SameSite? sameSite,
}) {
  if (_complete) {
    throw ArrowException('Cannot set cookie after response has been sent.');
  }
  final cookie = io.Cookie(name, value);
  if (maxAge != null) cookie.maxAge = maxAge.inSeconds;
  if (expires != null) cookie.expires = expires;
  if (path != null) cookie.path = path;
  if (domain != null) cookie.domain = domain;
  cookie.httpOnly = httpOnly;
  cookie.secure = secure;
  if (sameSite != null) cookie.sameSite = sameSite;
  _request.innerRequest.response.cookies.add(cookie);
}

/// Clear a cookie by setting it with an empty value and maxAge of 0.
///
/// This sends a Set-Cookie header that instructs the client to delete
/// the cookie. The [path] and [domain] must match the original cookie
/// for the browser to recognize which cookie to delete.
///
/// ```dart
/// req.respond.clearCookie('session', path: '/');
/// return req.respond.ok(data: {'loggedOut': true});
/// ```
void clearCookie(String name, {String? path, String? domain}) {
  setCookie(name, '', maxAge: Duration.zero, path: path, domain: domain);
}
```

**Why:**
- `setCookie()` returns `void` — it's preparatory, not terminal (like setting headers)
- Multiple cookies can be set by calling `setCookie()` multiple times
- `httpOnly: true` default prevents XSS attacks (secure by default)
- `secure: false` default allows local HTTP development (production apps should set `secure: true`)
- `maxAge` takes `Duration` (more ergonomic than raw seconds)
- `clearCookie()` is a convenience — matches Express's `res.clearCookie()`
- `_complete` check prevents setting cookies after response is sent (consistency with rest of Responder)

**No new imports needed** — `dart:io as io;` already imported.

### Step 4: Comprehensive Tests

**New file:** `arrow/test/unit/cookie_test.dart`

Create ~25-30 tests covering all cookie functionality:

```dart
import 'dart:io' as io;
import 'package:test/test.dart';
import 'package:arrow/src/request.dart';
import 'package:arrow/src/arrow_exception.dart';
import '../test_helpers.dart';

void main() {
  group('Cookie Support', () {
    tearDownAll(() async {
      await cleanupAllMockRequests();
    });

    group('req.cookies', () {
      test('should return empty map when no cookies present', () async {
        final httpReq = await createMockHttpRequest();
        final request = Request(httpReq);

        expect(request.cookies, isEmpty);
        expect(request.cookies, isA<Map<String, String>>());

        await cleanupMockRequest(httpReq);
      });

      test('should return map of cookie name-value pairs', () async {
        final httpReq = await createMockHttpRequest(
          cookies: {'session': 'abc123', 'theme': 'dark'},
        );
        final request = Request(httpReq);

        expect(request.cookies, equals({'session': 'abc123', 'theme': 'dark'}));

        await cleanupMockRequest(httpReq);
      });

      test('should handle single cookie', () async {
        final httpReq = await createMockHttpRequest(
          cookies: {'token': 'xyz789'},
        );
        final request = Request(httpReq);

        expect(request.cookies, equals({'token': 'xyz789'}));

        await cleanupMockRequest(httpReq);
      });

      test('should return same map on repeated access (caching)', () async {
        final httpReq = await createMockHttpRequest(
          cookies: {'session': 'abc'},
        );
        final request = Request(httpReq);

        final first = request.cookies;
        final second = request.cookies;

        expect(identical(first, second), isTrue);

        await cleanupMockRequest(httpReq);
      });
    });

    group('req.cookie()', () {
      test('should return value for existing cookie', () async {
        final httpReq = await createMockHttpRequest(
          cookies: {'session': 'abc123'},
        );
        final request = Request(httpReq);

        expect(request.cookie('session'), equals('abc123'));

        await cleanupMockRequest(httpReq);
      });

      test('should return null for missing cookie', () async {
        final httpReq = await createMockHttpRequest(
          cookies: {'session': 'abc123'},
        );
        final request = Request(httpReq);

        expect(request.cookie('missing'), isNull);

        await cleanupMockRequest(httpReq);
      });

      test('should return defaultValue for missing cookie', () async {
        final httpReq = await createMockHttpRequest(
          cookies: {'session': 'abc123'},
        );
        final request = Request(httpReq);

        expect(request.cookie('theme', defaultValue: 'light'), equals('light'));

        await cleanupMockRequest(httpReq);
      });

      test('should return actual value over defaultValue', () async {
        final httpReq = await createMockHttpRequest(
          cookies: {'theme': 'dark'},
        );
        final request = Request(httpReq);

        expect(request.cookie('theme', defaultValue: 'light'), equals('dark'));

        await cleanupMockRequest(httpReq);
      });

      test('should handle cookie with empty value', () async {
        final httpReq = await createMockHttpRequest(
          cookies: {'empty': ''},
        );
        final request = Request(httpReq);

        expect(request.cookie('empty'), equals(''));

        await cleanupMockRequest(httpReq);
      });
    });

    group('req.respond.setCookie()', () {
      test('should add cookie to response', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('session', 'abc123', path: '/');

        final responseCookies = req.innerRequest.response.cookies;
        expect(responseCookies.length, equals(1));
        expect(responseCookies[0].name, equals('session'));
        expect(responseCookies[0].value, equals('abc123'));
        expect(responseCookies[0].httpOnly, isTrue); // default
        expect(responseCookies[0].path, equals('/'));

        await cleanupMockRequest(httpReq);
      });

      test('should set httpOnly to true by default', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('token', 'xyz');

        expect(req.innerRequest.response.cookies[0].httpOnly, isTrue);

        await cleanupMockRequest(httpReq);
      });

      test('should allow httpOnly false', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('public', 'data', httpOnly: false);

        expect(req.innerRequest.response.cookies[0].httpOnly, isFalse);

        await cleanupMockRequest(httpReq);
      });

      test('should set secure flag', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('session', 'abc', secure: true);

        expect(req.innerRequest.response.cookies[0].secure, isTrue);

        await cleanupMockRequest(httpReq);
      });

      test('should set maxAge from Duration', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('session', 'abc', maxAge: Duration(hours: 1));

        expect(req.innerRequest.response.cookies[0].maxAge, equals(3600));

        await cleanupMockRequest(httpReq);
      });

      test('should set expires', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final expiry = DateTime.now().add(Duration(days: 7));

        req.respond.setCookie('session', 'abc', expires: expiry);

        final cookie = req.innerRequest.response.cookies[0];
        expect(cookie.expires, isNotNull);
        expect(cookie.expires!.difference(expiry).inSeconds, lessThan(2));

        await cleanupMockRequest(httpReq);
      });

      test('should set path', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('session', 'abc', path: '/api');

        expect(req.innerRequest.response.cookies[0].path, equals('/api'));

        await cleanupMockRequest(httpReq);
      });

      test('should set domain', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('session', 'abc', domain: 'example.com');

        expect(req.innerRequest.response.cookies[0].domain, equals('example.com'));

        await cleanupMockRequest(httpReq);
      });

      test('should set sameSite', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('session', 'abc', sameSite: io.SameSite.strict);

        expect(req.innerRequest.response.cookies[0].sameSite,
            equals(io.SameSite.strict));

        await cleanupMockRequest(httpReq);
      });

      test('should allow multiple cookies', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('session', 'abc123');
        req.respond.setCookie('theme', 'dark');

        expect(req.innerRequest.response.cookies.length, equals(2));
        expect(req.innerRequest.response.cookies[0].name, equals('session'));
        expect(req.innerRequest.response.cookies[1].name, equals('theme'));

        await cleanupMockRequest(httpReq);
      });

      test('should throw if response already sent', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.ok(data: {'test': true});

        expect(
          () => req.respond.setCookie('session', 'abc'),
          throwsA(isA<ArrowException>()),
        );

        await cleanupMockRequest(httpReq);
      });

      test('should work with ok() after setCookie', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('session', 'new-session',
            httpOnly: true,
            secure: true,
            maxAge: Duration(hours: 1),
            path: '/',
            sameSite: io.SameSite.strict);
        final response = req.respond.ok(data: {'loggedIn': true});

        expect(response.data, equals({'loggedIn': true}));
        expect(req.innerRequest.response.cookies.length, equals(1));

        await cleanupMockRequest(httpReq);
      });

      test('should work with badRequest() after setCookie', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('attempt', 'failed');
        req.respond.badRequest(msg: 'Invalid credentials');

        expect(req.innerRequest.response.cookies.length, equals(1));
        expect(req.innerRequest.response.statusCode, equals(400));

        await cleanupMockRequest(httpReq);
      });

      test('should work with error() after setCookie', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('rate-limit', 'exceeded');
        req.respond.error(429, msg: 'Too Many Requests');

        expect(req.innerRequest.response.cookies.length, equals(1));
        expect(req.innerRequest.response.statusCode, equals(429));

        await cleanupMockRequest(httpReq);
      });
    });

    group('req.respond.clearCookie()', () {
      test('should set cookie with empty value and maxAge 0', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.clearCookie('session', path: '/');

        final cookie = req.innerRequest.response.cookies[0];
        expect(cookie.name, equals('session'));
        expect(cookie.value, equals(''));
        expect(cookie.maxAge, equals(0));

        await cleanupMockRequest(httpReq);
      });

      test('should pass path to setCookie', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.clearCookie('session', path: '/api');

        expect(req.innerRequest.response.cookies[0].path, equals('/api'));

        await cleanupMockRequest(httpReq);
      });

      test('should pass domain to setCookie', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.clearCookie('session', domain: 'example.com');

        expect(
            req.innerRequest.response.cookies[0].domain, equals('example.com'));

        await cleanupMockRequest(httpReq);
      });

      test('should throw if response already sent', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.ok(data: {'test': true});

        expect(
          () => req.respond.clearCookie('session'),
          throwsA(isA<ArrowException>()),
        );

        await cleanupMockRequest(httpReq);
      });
    });
  });
}
```

**Test Coverage:**
- ~28 tests total
- Covers all cookie reading methods (cookies getter, cookie() method)
- Covers all cookie writing methods (setCookie with all options, clearCookie)
- Covers edge cases (empty cookies, caching, multiple cookies, order of operations)
- Covers error cases (setting cookies after response sent)

## Files Modified

| File | Lines Added | Lines Modified |
|------|-------------|----------------|
| `arrow/lib/src/request.dart` | ~35 | 0 |
| `arrow/lib/src/responder.dart` | ~60 | 0 |
| `arrow/test/test_helpers.dart` | ~10 | ~5 |
| `arrow/test/unit/cookie_test.dart` | ~280 (new) | N/A |
| **Total** | **~385** | **~5** |

## Verification Checklist

- [ ] Create `feature/cookie-support` branch from `dev`
- [ ] Add `cookies` parameter to `createMockHttpRequest` in test_helpers.dart
- [ ] Add cookie reading methods to Request class
- [ ] Add cookie writing methods to Responder class
- [ ] Create comprehensive test file with ~28 tests
- [ ] Run `dart analyze arrow/lib/` — verify no issues
- [ ] Run `dart test arrow/test/` — verify all tests pass (~193 total)
- [ ] Commit and push feature branch
- [ ] Merge to `dev`
- [ ] Push `dev` branch

## Future Enhancements (Out of Scope)

These are explicitly deferred for future consideration:

1. **Signed cookies** — HMAC-based cookie signing for tamper protection
   - Requires crypto library (package:crypto or use existing pointycastle)
   - Requires secret key configuration
   - More relevant for session-based web apps than REST APIs
   - Could be implemented as a separate middleware

2. **Encrypted cookies** — Full cookie encryption for sensitive data
   - Requires encryption library
   - Requires key management
   - REST APIs should use JWT tokens for sensitive auth data

3. **Cookie parser middleware** — Not needed since dart:io handles parsing
   - Original plan suggested this but it's unnecessary
   - Direct getters on Request are more ergonomic

## Security Considerations

1. **httpOnly default** — Prevents XSS attacks by blocking JavaScript access to cookies
2. **secure in production** — Developers must explicitly set `secure: true` for HTTPS-only transmission
3. **sameSite** — Recommended for CSRF protection (`SameSite.strict` or `SameSite.lax`)
4. **Path and domain scoping** — Limit cookie scope to minimize exposure
5. **maxAge vs expires** — Prefer `maxAge` for simpler relative expiration

## References

- Express.js cookies: https://expressjs.com/en/api.html#res.cookie
- Gin (Go) cookies: https://pkg.go.dev/github.com/gin-gonic/gin#Context.Cookie
- MDN Set-Cookie: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie
- Dart HttpCookie: https://api.dart.dev/stable/dart-io/Cookie-class.html
