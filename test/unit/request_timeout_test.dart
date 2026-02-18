import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:arrow/src/router.dart';
import 'package:arrow/src/request.dart';

void main() {
  group('Request Timeouts', () {
    late HttpClient client;

    setUp(() {
      client = HttpClient();
    });

    tearDown(() {
      client.close();
    });

    Future<(HttpServer, int)> startServer({
      required Duration timeout,
      required Duration handlerDelay,
    }) async {
      final router = Router()
        ..get('/slow', (Request req) async {
          await Future.delayed(handlerDelay);
          return req.respond.ok(data: {'done': true});
        })
        ..get('/fast', (Request req) async {
          return req.respond.ok(data: {'fast': true});
        });

      final server = await HttpServer.bind('localhost', 0);
      server.listen((httpReq) {
        Future<void> pipeline = router.serve(Request(httpReq)).then((_) {
          httpReq.response.close();
        });
        pipeline = pipeline.timeout(timeout, onTimeout: () {
          try {
            final body = json.encode({
              'ok': false,
              'errorMessage': 'Request Timeout',
              'errors': const {},
            });
            httpReq.response.statusCode = HttpStatus.requestTimeout;
            httpReq.response.headers.set(HttpHeaders.contentTypeHeader,
                'application/json; charset=utf-8');
            httpReq.response.write(body);
          } catch (_) {
          } finally {
            httpReq.response.close();
          }
        });
      });

      return (server, server.port);
    }

    test('should return 408 when handler exceeds timeout', () async {
      final (server, port) = await startServer(
        timeout: Duration(milliseconds: 50),
        handlerDelay: Duration(milliseconds: 200),
      );
      try {
        final req = await client.get('localhost', port, '/slow');
        final res = await req.close();

        expect(res.statusCode, equals(408));

        final body = await utf8.decoder.bind(res).join();
        final data = json.decode(body);
        expect(data['ok'], isFalse);
        expect(data['errorMessage'], equals('Request Timeout'));
      } finally {
        await server.close();
      }
    });

    test('should return 200 when handler completes within timeout', () async {
      final (server, port) = await startServer(
        timeout: Duration(seconds: 5),
        handlerDelay: Duration(milliseconds: 10),
      );
      try {
        final req = await client.get('localhost', port, '/fast');
        final res = await req.close();

        expect(res.statusCode, equals(200));

        final body = await utf8.decoder.bind(res).join();
        final data = json.decode(body);
        expect(data['ok'], isTrue);
        expect(data['data']['fast'], isTrue);
      } finally {
        await server.close();
      }
    });

    test('should return standard JSON error envelope on timeout', () async {
      final (server, port) = await startServer(
        timeout: Duration(milliseconds: 50),
        handlerDelay: Duration(milliseconds: 200),
      );
      try {
        final req = await client.get('localhost', port, '/slow');
        final res = await req.close();

        final body = await utf8.decoder.bind(res).join();
        final data = json.decode(body) as Map<String, dynamic>;

        expect(data.containsKey('ok'), isTrue);
        expect(data.containsKey('errorMessage'), isTrue);
        expect(data.containsKey('errors'), isTrue);
        expect(data['ok'], isFalse);
      } finally {
        await server.close();
      }
    });

    test('timeout response has correct Content-Type header', () async {
      final (server, port) = await startServer(
        timeout: Duration(milliseconds: 50),
        handlerDelay: Duration(milliseconds: 200),
      );
      try {
        final req = await client.get('localhost', port, '/slow');
        final res = await req.close();

        expect(res.headers.contentType?.mimeType,
            equals('application/json'));
      } finally {
        await server.close();
      }
    });
  });
}
