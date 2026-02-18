import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:test/test.dart';
import 'package:arrow/src/router.dart';
import 'package:arrow/src/request.dart';

void main() {
  group('Graceful Shutdown', () {
    late HttpClient client;

    setUp(() {
      client = HttpClient();
    });

    tearDown(() {
      client.close();
    });

    test('should respond 503 to requests arriving during shutdown', () async {
      // Create a server with a slow handler that gives us time to trigger shutdown.
      final handlerStarted = Completer<void>();
      final router = Router()
        ..get('/slow', (Request req) async {
          handlerStarted.complete();
          await Future.delayed(Duration(milliseconds: 300));
          return req.respond.ok(data: {'done': true});
        });

      final server = await HttpServer.bind('localhost', 0);
      final port = server.port;
      var shuttingDown = false;
      var inFlightRequests = 0;
      final drainCompleter = Completer<void>();

      server.listen((httpReq) {
        if (shuttingDown) {
          httpReq.response.statusCode = HttpStatus.serviceUnavailable;
          httpReq.response.headers.set(HttpHeaders.contentTypeHeader,
              'application/json; charset=utf-8');
          httpReq.response.write(json.encode({
            'ok': false,
            'errorMessage': 'Server is shutting down',
            'errors': const {},
          }));
          httpReq.response.close();
          return;
        }

        inFlightRequests++;
        router.serve(Request(httpReq)).then((_) {
          httpReq.response.close();
        }).whenComplete(() {
          inFlightRequests--;
          if (shuttingDown && inFlightRequests == 0) {
            drainCompleter.complete();
          }
        });
      });

      try {
        // Start a slow request.
        final slowFuture =
            client.get('localhost', port, '/slow').then((req) => req.close());

        // Wait for the handler to start.
        await handlerStarted.future;

        // Trigger shutdown.
        shuttingDown = true;

        // A new request during shutdown should get 503.
        final newReq = await client.get('localhost', port, '/slow');
        final newRes = await newReq.close();

        expect(newRes.statusCode, equals(503));
        final body = await utf8.decoder.bind(newRes).join();
        final data = json.decode(body);
        expect(data['ok'], isFalse);
        expect(data['errorMessage'], equals('Server is shutting down'));

        // The slow request should still complete successfully.
        final slowRes = await slowFuture;
        expect(slowRes.statusCode, equals(200));

        // Wait for drain.
        await drainCompleter.future.timeout(Duration(seconds: 2));
        expect(inFlightRequests, equals(0));
      } finally {
        await server.close();
      }
    });

    test('should drain in-flight requests before closing', () async {
      final handlerCompleted = Completer<void>();
      final router = Router()
        ..get('/work', (Request req) async {
          await Future.delayed(Duration(milliseconds: 100));
          handlerCompleted.complete();
          return req.respond.ok(data: {'completed': true});
        });

      final server = await HttpServer.bind('localhost', 0);
      final port = server.port;
      var inFlightRequests = 0;
      final allDrained = Completer<void>();

      server.listen((httpReq) {
        inFlightRequests++;
        router.serve(Request(httpReq)).then((_) {
          httpReq.response.close();
        }).whenComplete(() {
          inFlightRequests--;
          if (inFlightRequests == 0 && !allDrained.isCompleted) {
            allDrained.complete();
          }
        });
      });

      try {
        // Fire a request.
        final req = await client.get('localhost', port, '/work');
        final res = await req.close();

        // Request should complete normally.
        expect(res.statusCode, equals(200));
        await handlerCompleted.future;
        await allDrained.future.timeout(Duration(seconds: 2));
        expect(inFlightRequests, equals(0));
      } finally {
        await server.close();
      }
    });

    test('shutdown timeout response has standard JSON envelope', () async {
      final router = Router()
        ..get('/slow', (Request req) async {
          await Future.delayed(Duration(seconds: 5));
          return req.respond.ok(data: {});
        });

      final server = await HttpServer.bind('localhost', 0);
      final port = server.port;
      var shuttingDown = false;

      server.listen((httpReq) {
        if (shuttingDown) {
          httpReq.response.statusCode = HttpStatus.serviceUnavailable;
          httpReq.response.headers.set(HttpHeaders.contentTypeHeader,
              'application/json; charset=utf-8');
          httpReq.response.write(json.encode({
            'ok': false,
            'errorMessage': 'Server is shutting down',
            'errors': const {},
          }));
          httpReq.response.close();
          return;
        }
        router.serve(Request(httpReq)).then((_) {
          httpReq.response.close();
        });
      });

      try {
        shuttingDown = true;

        final req = await client.get('localhost', port, '/slow');
        final res = await req.close();
        final body = await utf8.decoder.bind(res).join();
        final data = json.decode(body) as Map<String, dynamic>;

        expect(data.containsKey('ok'), isTrue);
        expect(data.containsKey('errorMessage'), isTrue);
        expect(data.containsKey('errors'), isTrue);
        expect(res.headers.contentType?.mimeType, equals('application/json'));
      } finally {
        await server.close();
      }
    });
  });
}
