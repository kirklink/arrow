import 'package:test/test.dart';
import 'package:arrow/src/request.dart';
import 'package:arrow/src/middlewares/enforce_json_content_types.dart';
import '../test_helpers.dart';

void main() {
  group('enforceJsonContentType()', () {
    tearDownAll(() async {
      await cleanupAllMockRequests();
    });

    test('should return a RequestMiddleware function', () {
      final middleware = enforceJsonContentType();
      expect(middleware, isA<Function>());
    });

    test('should reject POST without application/json Content-Type', () async {
      final httpReq = await createMockHttpRequest(
        method: 'POST',
        headers: {'Content-Type': 'text/plain'},
      );
      final req = Request(httpReq);

      await enforceJsonContentType()(req);

      expect(req.innerRequest.response.statusCode, equals(400));

      await cleanupMockRequest(httpReq);
    });

    test('should reject GET with Content-Type set', () async {
      final httpReq = await createMockHttpRequest(
        headers: {'Content-Type': 'application/json'},
      );
      final req = Request(httpReq);

      await enforceJsonContentType()(req);

      expect(req.innerRequest.response.statusCode, equals(400));

      await cleanupMockRequest(httpReq);
    });

    test('should pass through POST with application/json', () async {
      final httpReq = await createMockPostRequest();
      final req = Request(httpReq);

      final result = await enforceJsonContentType()(req);

      expect(result.isAlive, isTrue);

      await cleanupMockRequest(httpReq);
    });

    test('should pass through GET without Content-Type', () async {
      final httpReq = await createMockHttpRequest();
      final req = Request(httpReq);

      final result = await enforceJsonContentType()(req);

      expect(result.isAlive, isTrue);

      await cleanupMockRequest(httpReq);
    });
  });
}
