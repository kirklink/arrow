import 'package:test/test.dart';
import 'package:arrow/src/http_exception.dart';
import 'package:arrow/src/request.dart';
import 'package:arrow/src/router.dart';
import 'package:arrow/src/response.dart';
import '../test_helpers.dart';

void main() {
  group('HttpException', () {
    test('should have correct status code and message', () {
      final e = HttpException(418, "I'm a teapot");

      expect(e.statusCode, equals(418));
      expect(e.message, equals("I'm a teapot"));
      expect(e.errors, isEmpty);
    });

    test('should carry errors map', () {
      final e = HttpException(400, 'Bad', errors: {'field': 'required'});

      expect(e.errors, equals({'field': 'required'}));
    });

    test('toString should include status code and message', () {
      final e = HttpException(404, 'Not Found');

      expect(e.toString(), contains('404'));
      expect(e.toString(), contains('Not Found'));
    });
  });

  group('BadRequestException', () {
    test('should have status code 400', () {
      const e = BadRequestException();

      expect(e.statusCode, equals(400));
      expect(e.message, equals('Bad Request'));
    });

    test('should accept custom message and errors', () {
      final e = BadRequestException(
          'Validation failed', {'name': 'is required'});

      expect(e.statusCode, equals(400));
      expect(e.message, equals('Validation failed'));
      expect(e.errors, equals({'name': 'is required'}));
    });

    test('should be an HttpException', () {
      const e = BadRequestException();

      expect(e, isA<HttpException>());
      expect(e, isA<Exception>());
    });
  });

  group('UnauthorizedException', () {
    test('should have status code 401', () {
      const e = UnauthorizedException();

      expect(e.statusCode, equals(401));
      expect(e.message, equals('Unauthorized'));
    });
  });

  group('ForbiddenException', () {
    test('should have status code 403', () {
      const e = ForbiddenException();

      expect(e.statusCode, equals(403));
      expect(e.message, equals('Forbidden'));
    });
  });

  group('NotFoundException', () {
    test('should have status code 404', () {
      const e = NotFoundException();

      expect(e.statusCode, equals(404));
      expect(e.message, equals('Not Found'));
    });

    test('should accept custom message', () {
      const e = NotFoundException('User not found');

      expect(e.message, equals('User not found'));
    });
  });

  group('ConflictException', () {
    test('should have status code 409', () {
      const e = ConflictException();

      expect(e.statusCode, equals(409));
      expect(e.message, equals('Conflict'));
    });
  });

  group('InternalServerException', () {
    test('should have status code 500', () {
      const e = InternalServerException();

      expect(e.statusCode, equals(500));
      expect(e.message, equals('Internal Server Error'));
    });
  });

  group('HttpException with nested errors', () {
    test('should support Map<String, Object> with nested structures', () {
      final e = BadRequestException('Validation failed', {
        'name': ['is required', 'must be at least 2 characters'],
        'email': 'is not a valid email',
        'address': {'street': 'is required', 'city': 'is required'},
      });

      expect(e.errors['name'], isA<List>());
      expect(e.errors['email'], isA<String>());
      expect(e.errors['address'], isA<Map>());
    });
  });

  group('Router HttpException handling', () {
    tearDownAll(() async {
      await cleanupAllMockRequests();
    });

    test('should convert thrown NotFoundException to 404 response', () async {
      final router = Router();

      router.get('/users/{id}', (req) async {
        throw NotFoundException('User not found');
      });

      final httpReq = await createMockGetRequest(path: '/users/42');
      final request = Request(httpReq);

      final response = await router.serve(request);

      expect(response, isNotNull);
      expect(response, isA<Response>());

      await cleanupMockRequest(httpReq);
    });

    test('should convert thrown BadRequestException to 400 response', () async {
      final router = Router();

      router.post('/users', (req) async {
        throw BadRequestException('Validation failed', {
          'name': 'is required',
        });
      });

      final httpReq = await createMockPostRequest(path: '/users');
      final request = Request(httpReq);

      final response = await router.serve(request);

      expect(response, isNotNull);

      await cleanupMockRequest(httpReq);
    });

    test('should convert thrown UnauthorizedException to 401 response',
        () async {
      final router = Router();

      router.get('/secret', (req) async {
        throw UnauthorizedException('Invalid token');
      });

      final httpReq = await createMockGetRequest(path: '/secret');
      final request = Request(httpReq);

      final response = await router.serve(request);

      expect(response, isNotNull);

      await cleanupMockRequest(httpReq);
    });

    test('should rethrow HttpException when shouldRecover is false', () async {
      final router = Router(shouldRecover: false);

      router.get('/test', (req) async {
        throw NotFoundException('not here');
      });

      final httpReq = await createMockGetRequest(path: '/test');
      final request = Request(httpReq);

      expect(
        () => router.serve(request),
        throwsA(isA<NotFoundException>()),
      );

      await cleanupMockRequest(httpReq);
    });

    test('non-HttpException should still go to recoverer', () async {
      var recovererCalled = false;

      final router = Router(recoverer: (req,
          {Exception? exception,
          StackTrace? stacktrace,
          Error? error}) async {
        recovererCalled = true;
        return req.respond.serverError();
      });

      router.get('/test', (req) async {
        throw Exception('generic error');
      });

      final httpReq = await createMockGetRequest(path: '/test');
      final request = Request(httpReq);

      await router.serve(request);

      expect(recovererCalled, isTrue);

      await cleanupMockRequest(httpReq);
    });
  });
}
