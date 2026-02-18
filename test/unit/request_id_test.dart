import 'package:test/test.dart';
import 'package:arrow/src/request.dart';
import 'package:arrow/src/middlewares/request_id.dart';
import '../test_helpers.dart';

void main() {
  group('requestId()', () {
    tearDownAll(() async {
      await cleanupAllMockRequests();
    });

    test('should return a RequestMiddleware function', () {
      final middleware = requestId();
      expect(middleware, isA<Function>());
    });

    test('should generate a UUID when no X-Request-ID header present',
        () async {
      final httpReq = await createMockHttpRequest();
      final req = Request(httpReq);

      await requestId()(req);

      final id = req.context.tryGet<String>(requestIdKey);
      expect(id, isNotNull);
      // UUID v4 format: 8-4-4-4-12 hex chars
      expect(
          id,
          matches(RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));

      await cleanupMockRequest(httpReq);
    });

    test('should use existing X-Request-ID header when present', () async {
      final httpReq = await createMockHttpRequest(
        headers: {'X-Request-ID': 'my-custom-id-123'},
      );
      final req = Request(httpReq);

      await requestId()(req);

      final id = req.context.tryGet<String>(requestIdKey);
      expect(id, equals('my-custom-id-123'));

      await cleanupMockRequest(httpReq);
    });

    test('should store ID in request context', () async {
      final httpReq = await createMockHttpRequest();
      final req = Request(httpReq);

      await requestId()(req);

      expect(req.context.tryGet<String>(requestIdKey), isNotNull);

      await cleanupMockRequest(httpReq);
    });

    test('should generate unique IDs for different requests', () async {
      final httpReq1 = await createMockHttpRequest();
      final httpReq2 = await createMockHttpRequest();
      final req1 = Request(httpReq1);
      final req2 = Request(httpReq2);

      await requestId()(req1);
      await requestId()(req2);

      final id1 = req1.context.tryGet<String>(requestIdKey);
      final id2 = req2.context.tryGet<String>(requestIdKey);
      expect(id1, isNot(equals(id2)));

      await cleanupMockRequest(httpReq1);
      await cleanupMockRequest(httpReq2);
    });

    test('should set X-Request-ID header on response', () async {
      final httpReq = await createMockHttpRequest();
      final req = Request(httpReq);

      await requestId()(req);

      final id = req.context.tryGet<String>(requestIdKey);
      final responseHeader =
          httpReq.response.headers.value('X-Request-ID');
      expect(responseHeader, equals(id));

      await cleanupMockRequest(httpReq);
    });

    test('should echo client-provided ID in response header', () async {
      final httpReq = await createMockHttpRequest(
        headers: {'X-Request-ID': 'trace-abc-456'},
      );
      final req = Request(httpReq);

      await requestId()(req);

      final responseHeader =
          httpReq.response.headers.value('X-Request-ID');
      expect(responseHeader, equals('trace-abc-456'));

      await cleanupMockRequest(httpReq);
    });
  });
}
