import 'package:test/test.dart';
import 'package:arrow/src/request.dart';
import 'package:arrow/src/middlewares/security_headers.dart';
import '../test_helpers.dart';

void main() {
  group('Security Headers Middleware', () {
    tearDownAll(() async {
      await cleanupAllMockRequests();
    });

    group('default config', () {
      test('should set all default headers', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final mw = securityHeaders();

        await mw(req);

        final headers = req.innerRequest.response.headers;
        expect(headers.value('X-Content-Type-Options'), equals('nosniff'));
        expect(headers.value('X-Frame-Options'), equals('DENY'));
        expect(headers.value('Strict-Transport-Security'),
            equals('max-age=15552000; includeSubDomains'));
        expect(headers.value('Referrer-Policy'), equals('no-referrer'));
        expect(headers.value('X-XSS-Protection'), equals('0'));
        expect(headers.value('Content-Security-Policy'),
            equals("default-src 'none'"));
        expect(headers.value('Cross-Origin-Resource-Policy'),
            equals('same-origin'));

        await cleanupMockRequest(httpReq);
      });

      test('should return the request unchanged', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final mw = securityHeaders();

        final result = await mw(req);

        expect(identical(result, req), isTrue);

        await cleanupMockRequest(httpReq);
      });
    });

    group('custom config', () {
      test('should override X-Frame-Options', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final mw = securityHeaders(
            SecurityHeadersConfig(frameOptions: 'SAMEORIGIN'));

        await mw(req);

        expect(req.innerRequest.response.headers.value('X-Frame-Options'),
            equals('SAMEORIGIN'));

        await cleanupMockRequest(httpReq);
      });

      test('should override Strict-Transport-Security', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final mw = securityHeaders(SecurityHeadersConfig(
            strictTransportSecurity: 'max-age=31536000'));

        await mw(req);

        expect(
            req.innerRequest.response.headers
                .value('Strict-Transport-Security'),
            equals('max-age=31536000'));

        await cleanupMockRequest(httpReq);
      });

      test('should override Content-Security-Policy', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final mw = securityHeaders(SecurityHeadersConfig(
            contentSecurityPolicy: "default-src 'self'"));

        await mw(req);

        expect(
            req.innerRequest.response.headers
                .value('Content-Security-Policy'),
            equals("default-src 'self'"));

        await cleanupMockRequest(httpReq);
      });

      test('should override Referrer-Policy', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final mw = securityHeaders(SecurityHeadersConfig(
            referrerPolicy: 'strict-origin-when-cross-origin'));

        await mw(req);

        expect(req.innerRequest.response.headers.value('Referrer-Policy'),
            equals('strict-origin-when-cross-origin'));

        await cleanupMockRequest(httpReq);
      });
    });

    group('disabling headers', () {
      test('should not set header when null', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final mw = securityHeaders(SecurityHeadersConfig(
          contentSecurityPolicy: null,
          xssProtection: null,
        ));

        await mw(req);

        final headers = req.innerRequest.response.headers;
        expect(headers.value('Content-Security-Policy'), isNull);
        expect(headers.value('X-XSS-Protection'), isNull);
        // Other defaults still present
        expect(headers.value('X-Content-Type-Options'), equals('nosniff'));
        expect(headers.value('X-Frame-Options'), equals('DENY'));

        await cleanupMockRequest(httpReq);
      });

      test('should disable all headers', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final mw = securityHeaders(SecurityHeadersConfig(
          contentTypeOptions: null,
          frameOptions: null,
          strictTransportSecurity: null,
          referrerPolicy: null,
          xssProtection: null,
          contentSecurityPolicy: null,
          crossOriginResourcePolicy: null,
        ));

        await mw(req);

        final headers = req.innerRequest.response.headers;
        expect(headers.value('X-Content-Type-Options'), isNull);
        expect(headers.value('X-Frame-Options'), isNull);
        expect(headers.value('Strict-Transport-Security'), isNull);
        expect(headers.value('Referrer-Policy'), isNull);
        expect(headers.value('X-XSS-Protection'), isNull);
        expect(headers.value('Content-Security-Policy'), isNull);
        expect(headers.value('Cross-Origin-Resource-Policy'), isNull);

        await cleanupMockRequest(httpReq);
      });
    });

    group('integration', () {
      test('headers persist after ok() response', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final mw = securityHeaders();

        await mw(req);
        req.respond.ok(data: {'test': true});

        final headers = req.innerRequest.response.headers;
        expect(headers.value('X-Content-Type-Options'), equals('nosniff'));
        expect(headers.value('X-Frame-Options'), equals('DENY'));

        await cleanupMockRequest(httpReq);
      });

      test('headers persist after error response', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final mw = securityHeaders();

        await mw(req);
        req.respond.badRequest(msg: 'Bad');

        final headers = req.innerRequest.response.headers;
        expect(headers.value('X-Content-Type-Options'), equals('nosniff'));
        expect(headers.value('Referrer-Policy'), equals('no-referrer'));

        await cleanupMockRequest(httpReq);
      });

      test('SecurityHeadersConfig const constructor', () {
        const config = SecurityHeadersConfig();
        expect(config.contentTypeOptions, equals('nosniff'));
        expect(config.frameOptions, equals('DENY'));
      });
    });
  });
}
