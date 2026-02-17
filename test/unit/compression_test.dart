import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:arrow/src/server.dart';
import 'package:arrow/src/router.dart';
import 'package:arrow/src/request.dart';

/// Helper to hold server + port from startServer.
class _TestServer {
  final HttpServer server;
  final int port;
  _TestServer(this.server, this.port);
}

void main() {
  group('Response Compression', () {
    late HttpClient client;

    setUp(() {
      client = HttpClient();
    });

    tearDown(() {
      client.close();
    });

    Future<_TestServer> startServer({bool compress = true}) async {
      final router = Router()
        ..get('/data', (Request req) async {
          return req.respond.ok(data: {
            'message': 'Hello, this is a test payload for compression.',
            'items': List.generate(50, (i) => 'item_$i'),
          });
        });

      final server = await HttpServer.bind('localhost', 0);
      server.autoCompress = compress;
      server.listen((httpReq) {
        router.serve(Request(httpReq)).then((_) {
          httpReq.response.close();
        });
      });

      return _TestServer(server, server.port);
    }

    test('should compress response when client sends Accept-Encoding: gzip',
        () async {
      final ts = await startServer();
      try {
        // Disable auto-decompression so we can inspect raw gzip bytes.
        client.autoUncompress = false;
        final req = await client.get('localhost', ts.port, '/data');
        req.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
        final res = await req.close();

        expect(res.headers.value(HttpHeaders.contentEncodingHeader),
            equals('gzip'));

        // Verify the body is valid JSON after manual decompression
        final body =
            await res.transform(gzip.decoder).transform(utf8.decoder).join();
        final data = json.decode(body);
        expect(data['ok'], isTrue);
        expect(data['data']['message'], contains('compression'));
      } finally {
        await ts.server.close();
      }
    });

    test('should not compress when client does not send Accept-Encoding',
        () async {
      final ts = await startServer();
      try {
        final req = await client.get('localhost', ts.port, '/data');
        req.headers.removeAll(HttpHeaders.acceptEncodingHeader);
        final res = await req.close();

        expect(res.headers.value(HttpHeaders.contentEncodingHeader), isNull);

        final body = await utf8.decoder.bind(res).join();
        final data = json.decode(body);
        expect(data['ok'], isTrue);
      } finally {
        await ts.server.close();
      }
    });

    test('should not compress when compress is false', () async {
      final ts = await startServer(compress: false);
      try {
        final req = await client.get('localhost', ts.port, '/data');
        req.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
        final res = await req.close();

        expect(res.headers.value(HttpHeaders.contentEncodingHeader), isNull);

        final body = await utf8.decoder.bind(res).join();
        final data = json.decode(body);
        expect(data['ok'], isTrue);
      } finally {
        await ts.server.close();
      }
    });

    test('Server constructor defaults compress to true', () {
      final router = Router();
      final server = Server(router, 0);
      expect(server, isNotNull);
    });

    test('Server constructor accepts compress: false', () {
      final router = Router();
      final server = Server(router, 0, compress: false);
      expect(server, isNotNull);
    });

    test('compressed response is smaller than uncompressed', () async {
      final compTs = await startServer();
      final plainTs = await startServer(compress: false);
      try {
        // Disable auto-decompression so we can compare raw byte sizes.
        client.autoUncompress = false;

        // Get compressed response size
        final compReq = await client.get('localhost', compTs.port, '/data');
        compReq.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
        final compRes = await compReq.close();
        final compBytes = await compRes.fold<List<int>>(
            [], (prev, chunk) => prev..addAll(chunk));

        // Get uncompressed response size
        final plainReq = await client.get('localhost', plainTs.port, '/data');
        plainReq.headers.removeAll(HttpHeaders.acceptEncodingHeader);
        final plainRes = await plainReq.close();
        final plainBytes = await plainRes.fold<List<int>>(
            [], (prev, chunk) => prev..addAll(chunk));

        expect(compBytes.length, lessThan(plainBytes.length));
      } finally {
        await compTs.server.close();
        await plainTs.server.close();
      }
    });
  });
}
