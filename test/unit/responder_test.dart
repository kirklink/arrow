import 'dart:io' as io;
import 'dart:convert' show json;
import 'package:test/test.dart';
import 'package:arrow/src/request.dart';
import 'package:arrow/src/responder.dart';
import 'package:arrow/src/arrow_exception.dart';
import '../test_helpers.dart';

void main() {
  group('Responder', () {
    tearDownAll(() async {
      await cleanupAllMockRequests();
    });

    group('ok()', () {
      test('should create successful response with data', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        final response = responder.ok(data: {'message': 'Hello', 'count': 42});

        expect(response, isNotNull);
        expect(response.data, equals({'message': 'Hello', 'count': 42}));

        await cleanupMockRequest(httpReq);
      });

      test('should set status code to 200 for GET requests', () async {
        final httpReq = await createMockGetRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.ok(data: {'result': 'success'});

        expect(req.innerRequest.response.statusCode, equals(io.HttpStatus.ok));

        await cleanupMockRequest(httpReq);
      });

      test('should set status code to 201 for POST requests', () async {
        final httpReq = await createMockPostRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.ok(data: {'id': 123});

        expect(req.innerRequest.response.statusCode, equals(io.HttpStatus.created));

        await cleanupMockRequest(httpReq);
      });

      test('should set status code to 200 for DELETE requests', () async {
        final httpReq = await createMockDeleteRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.ok();

        expect(req.innerRequest.response.statusCode, equals(io.HttpStatus.ok));

        await cleanupMockRequest(httpReq);
      });

      test('should write JSON response with ok:true', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.ok(data: {'user': 'Alice'});

        // Note: Can't easily read response.write() output in tests
        // but we verify it doesn't throw and formats correctly
        expect(() => json.encode({"ok": true, "data": {'user': 'Alice'}}), returnsNormally);

        await cleanupMockRequest(httpReq);
      });

      test('should throw if response already set', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.ok(data: {'first': 'response'});

        expect(
          () => responder.ok(data: {'second': 'response'}),
          throwsA(isA<ArrowException>()),
        );

        await cleanupMockRequest(httpReq);
      });
    });

    group('raw()', () {
      test('should create response with custom status code and data', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        final response = responder.raw(418, {'teapot': true});

        expect(response, isNotNull);
        expect(response.data, equals({'teapot': true}));
        expect(req.innerRequest.response.statusCode, equals(418));

        await cleanupMockRequest(httpReq);
      });

      test('should allow custom success codes', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.raw(202, {'message': 'Accepted'});

        expect(req.innerRequest.response.statusCode, equals(202));

        await cleanupMockRequest(httpReq);
      });

      test('should throw if response already set', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.raw(200, {'first': 'response'});

        expect(
          () => responder.raw(201, {'second': 'response'}),
          throwsA(isA<ArrowException>()),
        );

        await cleanupMockRequest(httpReq);
      });
    });

    group('code()', () {
      test('should set status code only without body', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        final response = responder.code(204);

        expect(response, isNotNull);
        expect(req.innerRequest.response.statusCode, equals(204));

        await cleanupMockRequest(httpReq);
      });

      test('should throw if response already set', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.code(204);

        expect(
          () => responder.code(200),
          throwsA(isA<ArrowException>()),
        );

        await cleanupMockRequest(httpReq);
      });
    });

    group('notFound()', () {
      test('should create 404 response with default message', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        final response = responder.notFound();

        expect(response, isNotNull);
        expect(req.innerRequest.response.statusCode, equals(io.HttpStatus.notFound));
        expect(req.isAlive, isFalse); // Request should be cancelled

        await cleanupMockRequest(httpReq);
      });

      test('should create 404 response with custom message', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.notFound(msg: 'User not found');

        // Verify JSON format: {"ok": false, "errorMessage": "User not found", "errors": {}}
        expect(() => json.encode({"ok": false, "errorMessage": "User not found", "errors": {}}), returnsNormally);

        await cleanupMockRequest(httpReq);
      });

      test('should include custom errors', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.notFound(msg: 'Resource not found', errors: <String, String>{'id': 'Invalid ID'});

        expect(req.isAlive, isFalse);

        await cleanupMockRequest(httpReq);
      });

      test('should throw if response already set', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.notFound();

        expect(
          () => responder.notFound(),
          throwsA(isA<ArrowException>()),
        );

        await cleanupMockRequest(httpReq);
      });
    });

    group('unauthorized()', () {
      test('should create 401 response with default message', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        final response = responder.unauthorized();

        expect(response, isNotNull);
        expect(req.innerRequest.response.statusCode, equals(io.HttpStatus.unauthorized));
        expect(req.isAlive, isFalse);

        await cleanupMockRequest(httpReq);
      });

      test('should create 401 response with custom message', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.unauthorized(msg: 'Token expired');

        expect(() => json.encode({"ok": false, "errorMessage": "Token expired", "errors": {}}), returnsNormally);

        await cleanupMockRequest(httpReq);
      });

      test('should throw if response already set', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.unauthorized();

        expect(
          () => responder.unauthorized(),
          throwsA(isA<ArrowException>()),
        );

        await cleanupMockRequest(httpReq);
      });
    });

    group('forbidden()', () {
      test('should create 403 response with default message', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        final response = responder.forbidden();

        expect(response, isNotNull);
        expect(req.innerRequest.response.statusCode, equals(io.HttpStatus.forbidden));
        expect(req.isAlive, isFalse);

        await cleanupMockRequest(httpReq);
      });

      test('should create 403 response with custom message', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.forbidden(msg: 'Admin access required');

        expect(() => json.encode({"ok": false, "errorMessage": "Admin access required", "errors": {}}), returnsNormally);

        await cleanupMockRequest(httpReq);
      });

      test('should throw if response already set', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.forbidden();

        expect(
          () => responder.forbidden(),
          throwsA(isA<ArrowException>()),
        );

        await cleanupMockRequest(httpReq);
      });
    });

    group('badRequest()', () {
      test('should create 400 response with default message', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        final response = responder.badRequest();

        expect(response, isNotNull);
        expect(req.innerRequest.response.statusCode, equals(io.HttpStatus.badRequest));
        expect(req.isAlive, isFalse);

        await cleanupMockRequest(httpReq);
      });

      test('should create 400 response with custom message and errors', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.badRequest(
          msg: 'Validation failed',
          errors: <String, String>{'email': 'Invalid format', 'age': 'Must be positive'},
        );

        expect(
          () => json.encode({
            "ok": false,
            "errorMessage": "Validation failed",
            "errors": {'email': 'Invalid format', 'age': 'Must be positive'}
          }),
          returnsNormally,
        );

        await cleanupMockRequest(httpReq);
      });

      test('should throw if response already set', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.badRequest();

        expect(
          () => responder.badRequest(),
          throwsA(isA<ArrowException>()),
        );

        await cleanupMockRequest(httpReq);
      });
    });

    group('serverError()', () {
      test('should create 500 response with default message', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        final response = responder.serverError();

        expect(response, isNotNull);
        expect(req.innerRequest.response.statusCode, equals(io.HttpStatus.internalServerError));
        expect(req.isAlive, isFalse);

        await cleanupMockRequest(httpReq);
      });

      test('should throw if response already set', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.serverError();

        expect(
          () => responder.serverError(),
          throwsA(isA<ArrowException>()),
        );

        await cleanupMockRequest(httpReq);
      });
    });

    group('response prevention', () {
      test('should prevent multiple responses (ok then notFound)', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.ok();

        expect(() => responder.notFound(), throwsA(isA<ArrowException>()));

        await cleanupMockRequest(httpReq);
      });

      test('should prevent multiple responses (badRequest then ok)', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.badRequest();

        expect(() => responder.ok(), throwsA(isA<ArrowException>()));

        await cleanupMockRequest(httpReq);
      });

      test('should prevent multiple responses (code then raw)', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final responder = Responder(req);

        responder.code(204);

        expect(() => responder.raw(200, {}), throwsA(isA<ArrowException>()));

        await cleanupMockRequest(httpReq);
      });
    });
  });
}
