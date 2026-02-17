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

    // ---- REQUEST: cookies getter ----

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

        expect(request.cookies['session'], equals('abc123'));
        expect(request.cookies['theme'], equals('dark'));
        expect(request.cookies.length, equals(2));

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

    // ---- REQUEST: cookie() method ----

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

    // ---- RESPONDER: setCookie() ----

    group('req.respond.setCookie()', () {
      test('should add cookie to response', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('session', 'abc123', path: '/');

        final cookies = req.innerRequest.response.cookies;
        expect(cookies.length, equals(1));
        expect(cookies[0].name, equals('session'));
        expect(cookies[0].value, equals('abc123'));
        expect(cookies[0].path, equals('/'));

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
        final expiry = DateTime.utc(2026, 12, 31);

        req.respond.setCookie('session', 'abc', expires: expiry);

        expect(req.innerRequest.response.cookies[0].expires, equals(expiry));

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

        expect(
            req.innerRequest.response.cookies[0].domain, equals('example.com'));

        await cleanupMockRequest(httpReq);
      });

      test('should set sameSite', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('session', 'abc',
            sameSite: io.SameSite.strict);

        expect(req.innerRequest.response.cookies[0].sameSite,
            equals(io.SameSite.strict));

        await cleanupMockRequest(httpReq);
      });

      test('should allow multiple cookies', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('session', 'abc123');
        req.respond.setCookie('theme', 'dark', httpOnly: false);

        final cookies = req.innerRequest.response.cookies;
        expect(cookies.length, equals(2));
        expect(cookies[0].name, equals('session'));
        expect(cookies[1].name, equals('theme'));

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

      test('should work before ok()', () async {
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

      test('should work before badRequest()', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('attempt', 'failed');
        req.respond.badRequest(msg: 'Invalid');

        expect(req.innerRequest.response.cookies.length, equals(1));
        expect(req.innerRequest.response.statusCode, equals(400));

        await cleanupMockRequest(httpReq);
      });

      test('should work before error()', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.setCookie('rate-limit', 'exceeded');
        req.respond.error(429, msg: 'Too Many Requests');

        expect(req.innerRequest.response.cookies.length, equals(1));
        expect(req.innerRequest.response.statusCode, equals(429));

        await cleanupMockRequest(httpReq);
      });
    });

    // ---- RESPONDER: clearCookie() ----

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

      test('should pass path through', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        req.respond.clearCookie('session', path: '/api');

        expect(req.innerRequest.response.cookies[0].path, equals('/api'));

        await cleanupMockRequest(httpReq);
      });

      test('should pass domain through', () async {
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
