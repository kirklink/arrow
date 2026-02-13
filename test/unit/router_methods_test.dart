import 'package:test/test.dart';
import 'package:arrow/src/constants.dart';
import 'package:arrow/src/router.dart';
import 'package:arrow/src/request.dart';
import 'package:arrow/src/response.dart';
import '../test_helpers.dart';

void main() {
  group('RouterMethods constants', () {
    test('should define PATCH method', () {
      expect(RouterMethods.PATCH, equals('PATCH'));
    });

    test('should define HEAD method', () {
      expect(RouterMethods.HEAD, equals('HEAD'));
    });

    test('should include PATCH in allowedMethods', () {
      expect(RouterMethods.allowedMethods, contains('PATCH'));
    });

    test('should include HEAD in allowedMethods', () {
      expect(RouterMethods.allowedMethods, contains('HEAD'));
    });

    test('should have 6 allowed methods', () {
      expect(RouterMethods.allowedMethods.length, equals(6));
    });

    test('allowedMethods should contain all HTTP methods', () {
      expect(
        RouterMethods.allowedMethods,
        containsAll(['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD']),
      );
    });
  });

  group('Router PATCH method', () {
    tearDownAll(() async {
      await cleanupAllMockRequests();
    });

    test('should register a PATCH route', () {
      final router = Router();

      // Should not throw
      final route = router.patch('/users/{id}', (req) async {
        return req.respond.ok(data: {'patched': true});
      });

      expect(route, isNotNull);
    });

    test('should handle PATCH requests', () async {
      final router = Router();

      router.patch('/items/{id}', (req) async {
        final id = req.params.get('id');
        return req.respond.ok(data: {'id': id, 'method': 'PATCH'});
      });

      final httpReq = await createMockPatchRequest(path: '/items/42');
      final request = Request(httpReq);

      final response = await router.serve(request);

      expect(response, isNotNull);
      expect(response, isA<Response>());

      await cleanupMockRequest(httpReq);
    });

    test('should not match PATCH route with GET request', () async {
      final router = Router();
      var patchCalled = false;

      router.patch('/items/{id}', (req) async {
        patchCalled = true;
        return req.respond.ok();
      });

      final httpReq = await createMockGetRequest(path: '/items/42');
      final request = Request(httpReq);

      await router.serve(request);

      expect(patchCalled, isFalse);

      await cleanupMockRequest(httpReq);
    });
  });

  group('Router HEAD method', () {
    tearDownAll(() async {
      await cleanupAllMockRequests();
    });

    test('should register a HEAD route', () {
      final router = Router();

      final route = router.head('/health', (req) async {
        return req.respond.code(200);
      });

      expect(route, isNotNull);
    });

    test('should handle HEAD requests', () async {
      final router = Router();

      router.head('/health', (req) async {
        return req.respond.code(200);
      });

      final httpReq = await createMockHttpRequest(
        path: '/health',
        method: 'HEAD',
      );
      final request = Request(httpReq);

      final response = await router.serve(request);

      expect(response, isNotNull);
      expect(response, isA<Response>());

      await cleanupMockRequest(httpReq);
    });

    test('should not match HEAD route with GET request', () async {
      final router = Router();
      var headCalled = false;

      router.head('/health', (req) async {
        headCalled = true;
        return req.respond.code(200);
      });

      final httpReq = await createMockGetRequest(path: '/health');
      final request = Request(httpReq);

      await router.serve(request);

      expect(headCalled, isFalse);

      await cleanupMockRequest(httpReq);
    });
  });

  group('Router with all HTTP methods', () {
    tearDownAll(() async {
      await cleanupAllMockRequests();
    });

    test('should register routes for all 6 methods on same path', () {
      final router = Router();

      // Should not throw for any method
      router.get('/resource', (req) async => req.respond.ok());
      router.post('/resource', (req) async => req.respond.ok());
      router.put('/resource', (req) async => req.respond.ok());
      router.delete('/resource', (req) async => req.respond.ok());
      router.patch('/resource', (req) async => req.respond.ok());
      router.head('/resource', (req) async => req.respond.code(200));
    });

    test('PATCH route should work in a group', () async {
      final router = Router();
      final api = router.group('/api');

      api.patch('/users/{id}', (req) async {
        return req.respond.ok(data: {'grouped': true});
      });

      final httpReq = await createMockPatchRequest(path: '/api/users/1');
      final request = Request(httpReq);

      final response = await router.serve(request);

      expect(response, isNotNull);

      await cleanupMockRequest(httpReq);
    });

    test('HEAD route should work in a group', () async {
      final router = Router();
      final api = router.group('/api');

      api.head('/status', (req) async {
        return req.respond.code(200);
      });

      final httpReq = await createMockHttpRequest(
        path: '/api/status',
        method: 'HEAD',
      );
      final request = Request(httpReq);

      final response = await router.serve(request);

      expect(response, isNotNull);

      await cleanupMockRequest(httpReq);
    });
  });
}
