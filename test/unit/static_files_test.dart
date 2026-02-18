import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:arrow/src/router.dart';
import 'package:arrow/src/request.dart';
import 'package:arrow/src/static_files.dart';
import 'package:arrow/src/mime_type.dart';

class _TestServer {
  final HttpServer server;
  final int port;
  _TestServer(this.server, this.port);
}

void main() {
  late Directory tempDir;
  late HttpClient client;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('arrow_static_test_');
    client = HttpClient();
  });

  tearDown(() {
    client.close();
    tempDir.deleteSync(recursive: true);
  });

  Future<_TestServer> startServer(Router router) async {
    final server = await HttpServer.bind('localhost', 0);
    server.listen((httpReq) {
      router.serve(Request(httpReq)).then((_) {
        httpReq.response.close();
      });
    });
    return _TestServer(server, server.port);
  }

  /// Helper to make a GET request and return the response.
  Future<HttpClientResponse> get(
      HttpClient client, int port, String path,
      {Map<String, String>? headers}) async {
    final req = await client.get('localhost', port, path);
    headers?.forEach((k, v) => req.headers.set(k, v));
    return req.close();
  }

  group('Static File Serving', () {
    test('serves an existing HTML file with correct Content-Type', () async {
      File('${tempDir.path}/index.html')
          .writeAsStringSync('<html><body>Hello</body></html>');
      final router = Router()..serveStaticFiles('/public', tempDir.path);
      final ts = await startServer(router);
      try {
        final res = await get(client, ts.port, '/public/index.html');
        expect(res.statusCode, equals(200));
        expect(res.headers.contentType.toString(),
            contains('text/html'));
        final body = await utf8.decoder.bind(res).join();
        expect(body, equals('<html><body>Hello</body></html>'));
      } finally {
        await ts.server.close();
      }
    });

    test('serves CSS file with correct Content-Type', () async {
      File('${tempDir.path}/style.css')
          .writeAsStringSync('body { color: red; }');
      final router = Router()..serveStaticFiles('/assets', tempDir.path);
      final ts = await startServer(router);
      try {
        final res = await get(client, ts.port, '/assets/style.css');
        expect(res.statusCode, equals(200));
        expect(res.headers.contentType.toString(), contains('text/css'));
        final body = await utf8.decoder.bind(res).join();
        expect(body, equals('body { color: red; }'));
      } finally {
        await ts.server.close();
      }
    });

    test('serves JavaScript file with correct Content-Type', () async {
      File('${tempDir.path}/app.js')
          .writeAsStringSync('console.log("hi");');
      final router = Router()..serveStaticFiles('/public', tempDir.path);
      final ts = await startServer(router);
      try {
        final res = await get(client, ts.port, '/public/app.js');
        expect(res.statusCode, equals(200));
        expect(res.headers.contentType.toString(),
            contains('application/javascript'));
      } finally {
        await ts.server.close();
      }
    });

    test('serves JSON file with correct Content-Type', () async {
      File('${tempDir.path}/data.json')
          .writeAsStringSync('{"key": "value"}');
      final router = Router()..serveStaticFiles('/public', tempDir.path);
      final ts = await startServer(router);
      try {
        final res = await get(client, ts.port, '/public/data.json');
        expect(res.statusCode, equals(200));
        expect(res.headers.contentType.toString(),
            contains('application/json'));
      } finally {
        await ts.server.close();
      }
    });

    test('sets Content-Length header', () async {
      final content = 'Hello, World!';
      File('${tempDir.path}/hello.txt').writeAsStringSync(content);
      final router = Router()..serveStaticFiles('/public', tempDir.path);
      final ts = await startServer(router);
      try {
        final res = await get(client, ts.port, '/public/hello.txt');
        expect(res.statusCode, equals(200));
        expect(res.contentLength, equals(content.length));
      } finally {
        await ts.server.close();
      }
    });

    test('serves index.html for directory path', () async {
      final subDir = Directory('${tempDir.path}/docs')..createSync();
      File('${subDir.path}/index.html')
          .writeAsStringSync('<html>Docs</html>');
      final router = Router()..serveStaticFiles('/public', tempDir.path);
      final ts = await startServer(router);
      try {
        final res = await get(client, ts.port, '/public/docs');
        expect(res.statusCode, equals(200));
        final body = await utf8.decoder.bind(res).join();
        expect(body, equals('<html>Docs</html>'));
      } finally {
        await ts.server.close();
      }
    });

    test('serves index.html for root prefix path', () async {
      File('${tempDir.path}/index.html')
          .writeAsStringSync('<html>Root</html>');
      final router = Router()..serveStaticFiles('/public', tempDir.path);
      final ts = await startServer(router);
      try {
        final res = await get(client, ts.port, '/public');
        expect(res.statusCode, equals(200));
        final body = await utf8.decoder.bind(res).join();
        expect(body, equals('<html>Root</html>'));
      } finally {
        await ts.server.close();
      }
    });

    test('returns 404 for non-existent file', () async {
      final router = Router()..serveStaticFiles('/public', tempDir.path);
      final ts = await startServer(router);
      try {
        final res = await get(client, ts.port, '/public/missing.txt');
        expect(res.statusCode, equals(404));
      } finally {
        await ts.server.close();
      }
    });

    test('falls through for non-matching URL prefix', () async {
      File('${tempDir.path}/test.txt').writeAsStringSync('test');
      final router = Router()
        ..serveStaticFiles('/public', tempDir.path)
        ..get('/api/hello', (req) async {
          return req.respond.ok(data: {'msg': 'hello'});
        });
      final ts = await startServer(router);
      try {
        // API route should still work
        final res = await get(client, ts.port, '/api/hello');
        expect(res.statusCode, equals(200));
        final body = await utf8.decoder.bind(res).join();
        final data = json.decode(body);
        expect(data['data']['msg'], equals('hello'));
      } finally {
        await ts.server.close();
      }
    });

    test('rejects path traversal attempts', () async {
      // Create a file outside the served directory
      final outsideFile = File('${tempDir.parent.path}/secret.txt');
      outsideFile.writeAsStringSync('secret data');
      final router = Router()..serveStaticFiles('/public', tempDir.path);
      final ts = await startServer(router);
      try {
        final res = await get(client, ts.port, '/public/../secret.txt');
        // Should not serve the file — either 404 or fall through
        expect(res.statusCode, isNot(200));
        final body = await utf8.decoder.bind(res).join();
        expect(body, isNot(contains('secret data')));
      } finally {
        await ts.server.close();
        outsideFile.deleteSync();
      }
    });

    test('only serves GET and HEAD requests', () async {
      File('${tempDir.path}/data.txt').writeAsStringSync('data');
      final router = Router()
        ..serveStaticFiles('/public', tempDir.path)
        ..post('/public/data.txt', (req) async {
          return req.respond.ok(data: {'posted': true});
        });
      final ts = await startServer(router);
      try {
        // POST should not be handled by static serving
        final postReq =
            await client.post('localhost', ts.port, '/public/data.txt');
        final postRes = await postReq.close();
        expect(postRes.statusCode, equals(201));
      } finally {
        await ts.server.close();
      }
    });

    test('HEAD returns headers but no body', () async {
      final content = 'Hello HEAD';
      File('${tempDir.path}/head.txt').writeAsStringSync(content);
      final router = Router()..serveStaticFiles('/public', tempDir.path);
      final ts = await startServer(router);
      try {
        final req = await client.head('localhost', ts.port, '/public/head.txt');
        final res = await req.close();
        expect(res.statusCode, equals(200));
        expect(res.contentLength, equals(content.length));
        // HEAD should return empty body
        final body = await utf8.decoder.bind(res).join();
        expect(body, isEmpty);
      } finally {
        await ts.server.close();
      }
    });

    group('ETag', () {
      test('sets ETag header', () async {
        File('${tempDir.path}/etag.txt').writeAsStringSync('etag test');
        final router = Router()..serveStaticFiles('/public', tempDir.path);
        final ts = await startServer(router);
        try {
          final res = await get(client, ts.port, '/public/etag.txt');
          expect(res.statusCode, equals(200));
          final etag = res.headers.value(HttpHeaders.etagHeader);
          expect(etag, isNotNull);
          expect(etag, startsWith('"'));
          expect(etag, endsWith('"'));
        } finally {
          await ts.server.close();
        }
      });

      test('returns 304 for matching If-None-Match', () async {
        File('${tempDir.path}/cached.txt').writeAsStringSync('cached');
        final router = Router()..serveStaticFiles('/public', tempDir.path);
        final ts = await startServer(router);
        try {
          // First request to get the ETag
          final res1 = await get(client, ts.port, '/public/cached.txt');
          final etag = res1.headers.value(HttpHeaders.etagHeader)!;
          await utf8.decoder.bind(res1).join(); // drain

          // Second request with If-None-Match
          final res2 = await get(client, ts.port, '/public/cached.txt',
              headers: {HttpHeaders.ifNoneMatchHeader: etag});
          expect(res2.statusCode, equals(304));
        } finally {
          await ts.server.close();
        }
      });

      test('returns 200 for non-matching If-None-Match', () async {
        File('${tempDir.path}/fresh.txt').writeAsStringSync('fresh');
        final router = Router()..serveStaticFiles('/public', tempDir.path);
        final ts = await startServer(router);
        try {
          final res = await get(client, ts.port, '/public/fresh.txt',
              headers: {HttpHeaders.ifNoneMatchHeader: '"wrong-etag"'});
          expect(res.statusCode, equals(200));
          final body = await utf8.decoder.bind(res).join();
          expect(body, equals('fresh'));
        } finally {
          await ts.server.close();
        }
      });

      test('does not set ETag when disabled', () async {
        File('${tempDir.path}/noetag.txt').writeAsStringSync('no etag');
        final router = Router()
          ..serveStaticFiles('/public', tempDir.path,
              StaticFilesConfig(etag: false));
        final ts = await startServer(router);
        try {
          final res = await get(client, ts.port, '/public/noetag.txt');
          expect(res.statusCode, equals(200));
          expect(res.headers.value(HttpHeaders.etagHeader), isNull);
        } finally {
          await ts.server.close();
        }
      });
    });

    group('Cache-Control', () {
      test('sets default Cache-Control header', () async {
        File('${tempDir.path}/cache.txt').writeAsStringSync('cache');
        final router = Router()..serveStaticFiles('/public', tempDir.path);
        final ts = await startServer(router);
        try {
          final res = await get(client, ts.port, '/public/cache.txt');
          expect(res.headers.value(HttpHeaders.cacheControlHeader),
              equals('public, max-age=3600'));
        } finally {
          await ts.server.close();
        }
      });

      test('uses custom maxAge', () async {
        File('${tempDir.path}/custom.txt').writeAsStringSync('custom');
        final router = Router()
          ..serveStaticFiles('/public', tempDir.path,
              StaticFilesConfig(maxAge: 86400));
        final ts = await startServer(router);
        try {
          final res = await get(client, ts.port, '/public/custom.txt');
          expect(res.headers.value(HttpHeaders.cacheControlHeader),
              equals('public, max-age=86400'));
        } finally {
          await ts.server.close();
        }
      });
    });

    group('Custom headers', () {
      test('sets additional custom headers', () async {
        File('${tempDir.path}/custom.txt').writeAsStringSync('custom');
        final router = Router()
          ..serveStaticFiles('/public', tempDir.path,
              StaticFilesConfig(headers: {'X-Custom': 'test-value'}));
        final ts = await startServer(router);
        try {
          final res = await get(client, ts.port, '/public/custom.txt');
          expect(res.headers.value('X-Custom'), equals('test-value'));
        } finally {
          await ts.server.close();
        }
      });
    });

    group('Index file', () {
      test('disabling index file returns 404 for directory', () async {
        final subDir = Directory('${tempDir.path}/noindex')..createSync();
        File('${subDir.path}/index.html')
            .writeAsStringSync('<html>Index</html>');
        final router = Router()
          ..serveStaticFiles('/public', tempDir.path,
              StaticFilesConfig(index: null));
        final ts = await startServer(router);
        try {
          final res = await get(client, ts.port, '/public/noindex');
          // Without index file serving, directory should 404
          expect(res.statusCode, equals(404));
        } finally {
          await ts.server.close();
        }
      });
    });

    group('Subdirectories', () {
      test('serves files in nested directories', () async {
        final subDir = Directory('${tempDir.path}/css')..createSync();
        File('${subDir.path}/main.css')
            .writeAsStringSync('.main { display: block; }');
        final router = Router()..serveStaticFiles('/public', tempDir.path);
        final ts = await startServer(router);
        try {
          final res = await get(client, ts.port, '/public/css/main.css');
          expect(res.statusCode, equals(200));
          expect(res.headers.contentType.toString(), contains('text/css'));
          final body = await utf8.decoder.bind(res).join();
          expect(body, equals('.main { display: block; }'));
        } finally {
          await ts.server.close();
        }
      });
    });
  });

  group('MimeType', () {
    test('fromPath returns correct type for known extensions', () {
      expect(MimeType.fromPath('style.css').value, contains('text/css'));
      expect(MimeType.fromPath('app.js').value,
          contains('application/javascript'));
      expect(MimeType.fromPath('data.json').value,
          contains('application/json'));
      expect(MimeType.fromPath('page.html').value, contains('text/html'));
      expect(MimeType.fromPath('image.png').value, equals('image/png'));
      expect(MimeType.fromPath('photo.jpg').value, equals('image/jpeg'));
      expect(MimeType.fromPath('icon.svg').value, contains('image/svg+xml'));
    });

    test('fromPath is case-insensitive', () {
      expect(MimeType.fromPath('FILE.HTML').value, contains('text/html'));
      expect(MimeType.fromPath('IMAGE.PNG').value, equals('image/png'));
    });

    test('fromPath returns fallback for unknown extensions', () {
      expect(MimeType.fromPath('data.xyz'), equals(MimeType.fallback));
    });

    test('fromPath returns fallback for no extension', () {
      expect(MimeType.fromPath('Makefile'), equals(MimeType.fallback));
    });

    test('fromPath handles full paths', () {
      expect(MimeType.fromPath('/var/www/css/style.css').value,
          contains('text/css'));
      expect(MimeType.fromPath('C:\\Users\\web\\index.html').value,
          contains('text/html'));
    });

    test('toString returns the MIME type value', () {
      expect(MimeType.html.toString(), contains('text/html'));
      expect(MimeType.png.toString(), equals('image/png'));
    });

    test('text types include charset=utf-8', () {
      expect(MimeType.html.value, contains('charset=utf-8'));
      expect(MimeType.css.value, contains('charset=utf-8'));
      expect(MimeType.javascript.value, contains('charset=utf-8'));
      expect(MimeType.json.value, contains('charset=utf-8'));
    });

    test('binary types do not include charset', () {
      expect(MimeType.png.value, isNot(contains('charset')));
      expect(MimeType.jpg.value, isNot(contains('charset')));
      expect(MimeType.pdf.value, isNot(contains('charset')));
      expect(MimeType.zip.value, isNot(contains('charset')));
    });
  });
}
