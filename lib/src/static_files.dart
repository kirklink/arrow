import 'dart:io';

import 'request.dart';
import 'response.dart';
import 'mime_type.dart';

/// Configuration for static file serving.
///
/// ```dart
/// // Serve with defaults (index.html, 1 hour cache, ETag enabled)
/// router.static('/public', 'web/public');
///
/// // Custom configuration
/// router.static('/assets', 'web/assets', StaticFilesConfig(
///   maxAge: 86400,
///   headers: {'X-Custom': 'value'},
/// ));
/// ```
class StaticFilesConfig {
  /// Index file to serve for directory requests.
  /// Set to `null` to disable index file serving.
  /// Defaults to `'index.html'`.
  final String? index;

  /// Cache-Control max-age in seconds. Defaults to 3600 (1 hour).
  final int maxAge;

  /// Whether to generate and check ETag headers for caching.
  /// Defaults to `true`.
  final bool etag;

  /// Additional headers to set on every static file response.
  final Map<String, String> headers;

  const StaticFilesConfig({
    this.index = 'index.html',
    this.maxAge = 3600,
    this.etag = true,
    this.headers = const <String, String>{},
  });
}

/// Internal mount point for static file serving.
class StaticMount {
  final String urlPrefix;
  final Directory directory;
  final StaticFilesConfig config;

  StaticMount(this.urlPrefix, String directoryPath, StaticFilesConfig? config)
      : directory = Directory(directoryPath),
        config = config ?? const StaticFilesConfig();

  /// Try to serve a static file for this request.
  /// Returns a [Response] if the file was served, or `null` to fall through.
  Future<Response?> tryServe(Request req) async {
    final method = req.method;
    if (method != 'GET' && method != 'HEAD') return null;

    final path = req.innerRequest.uri.path;
    if (!path.startsWith(urlPrefix)) return null;

    // Extract the relative path after the URL prefix.
    var relativePath = path.substring(urlPrefix.length);
    if (relativePath.startsWith('/')) {
      relativePath = relativePath.substring(1);
    }

    // Resolve the file path within the directory.
    final resolvedPath = Uri.decodeFull(relativePath);
    final file = File('${directory.path}/$resolvedPath');

    // Security: canonicalize and verify the path is within the directory.
    final canonicalDir = directory.absolute.path;
    final canonicalFile = file.absolute.path;
    if (!canonicalFile.startsWith(canonicalDir)) {
      return null; // Path traversal attempt — fall through.
    }

    var target = file;
    final stat = await target.stat();

    // If it's a directory, try the index file.
    if (stat.type == FileSystemEntityType.directory && config.index != null) {
      target = File('${target.path}/${config.index}');
      final indexStat = await target.stat();
      if (indexStat.type != FileSystemEntityType.file) return null;
    } else if (stat.type != FileSystemEntityType.file) {
      return null; // Not found — fall through to router's 404.
    }

    final fileStat = await target.stat();
    final srcResponse = req.innerRequest.response;

    // ETag: "mtime-size"
    if (config.etag) {
      final etag =
          '"${fileStat.modified.millisecondsSinceEpoch}-${fileStat.size}"';
      srcResponse.headers.set(HttpHeaders.etagHeader, etag);

      final ifNoneMatch = req.headers.value(HttpHeaders.ifNoneMatchHeader);
      if (ifNoneMatch == etag) {
        srcResponse.statusCode = HttpStatus.notModified;
        req.cancel();
        return Response(req);
      }
    }

    // Cache-Control
    srcResponse.headers
        .set(HttpHeaders.cacheControlHeader, 'public, max-age=${config.maxAge}');

    // Custom headers
    config.headers.forEach((name, value) {
      srcResponse.headers.set(name, value);
    });

    // Content-Type
    srcResponse.headers.set(HttpHeaders.contentTypeHeader,
        MimeType.fromPath(target.path).value);
    srcResponse.headers
        .set(HttpHeaders.contentLengthHeader, fileStat.size);

    srcResponse.statusCode = HttpStatus.ok;

    // HEAD: headers only, no body.
    if (method == 'HEAD') {
      req.cancel();
      return Response(req);
    }

    // GET: stream the file.
    await srcResponse.addStream(target.openRead());
    req.cancel();
    return Response(req);
  }
}
