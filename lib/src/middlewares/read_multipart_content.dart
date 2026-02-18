import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:mime/mime.dart';

import '../request.dart';
import '../request_middleware.dart';
import '../uploaded_file.dart';
import '../multipart_form_data.dart';

/// Configuration for multipart file upload parsing.
///
/// ```dart
/// // Default: 10MB per file, 50MB total, 10 files, any type
/// router.onRequest(readMultipartContent());
///
/// // Strict: small images only
/// router.onRequest(readMultipartContent(MultipartConfig(
///   maxFileSize: 2 * 1024 * 1024,  // 2MB
///   maxTotalSize: 10 * 1024 * 1024, // 10MB
///   maxFiles: 5,
///   allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
/// )));
/// ```
class MultipartConfig {
  /// Maximum size in bytes for a single file. Default: 10MB.
  final int maxFileSize;

  /// Maximum total size in bytes for all files combined. Default: 50MB.
  final int maxTotalSize;

  /// Maximum number of files allowed. Default: 10.
  final int maxFiles;

  /// Allowed MIME types for uploaded files.
  /// Empty list means all types are allowed.
  final List<String> allowedMimeTypes;

  const MultipartConfig({
    this.maxFileSize = 10 * 1024 * 1024,
    this.maxTotalSize = 50 * 1024 * 1024,
    this.maxFiles = 10,
    this.allowedMimeTypes = const <String>[],
  });
}

/// Middleware that parses multipart/form-data request bodies.
///
/// Reads the request body stream, parses each multipart part, and stores
/// the result as [MultipartFormData] on [req.context]. Handlers access
/// the result via [MultipartFormData.of(req)].
///
/// Non-multipart requests pass through unchanged, so this middleware
/// can coexist with [readJsonContent] on the same router.
///
/// ```dart
/// // Global: parse uploads on all routes
/// router.onRequest(readMultipartContent());
///
/// // Per-route with config
/// router.post('/upload', uploadHandler)
///   ..addOnRequest(readMultipartContent(MultipartConfig(
///     maxFileSize: 5 * 1024 * 1024,
///     allowedMimeTypes: ['image/jpeg', 'image/png'],
///   )));
/// ```
RequestMiddleware readMultipartContent([MultipartConfig? config]) {
  config ??= const MultipartConfig();
  return (Request req) async {
    return _readMultipartContent(req, config!);
  };
}

Future<Request> _readMultipartContent(
    Request req, MultipartConfig config) async {
  // Check Content-Type is multipart/form-data.
  final contentType = req.innerRequest.headers.contentType;
  if (contentType == null || contentType.mimeType != 'multipart/form-data') {
    return req;
  }

  // Extract boundary.
  final boundary = contentType.parameters['boundary'];
  if (boundary == null || boundary.isEmpty) {
    req.messenger.addError(
        '[readMultipartContent] Missing boundary in Content-Type header.');
    req.respond.badRequest(msg: 'Missing boundary in multipart request.');
    return req;
  }

  try {
    final transformer = MimeMultipartTransformer(boundary);
    final parts = transformer.bind(req.innerRequest);

    final fields = <String, String>{};
    final files = <UploadedFile>[];
    var totalSize = 0;

    await for (final part in parts) {
      final disposition = part.headers['content-disposition'];
      if (disposition == null) continue;

      final params = _parseContentDisposition(disposition);
      final name = params['name'];
      if (name == null) continue;

      final filename = params['filename'];

      if (filename != null) {
        // — File part —

        // File count limit.
        if (files.length >= config.maxFiles) {
          req.messenger.addError(
              '[readMultipartContent] Too many files (max: ${config.maxFiles}).');
          req.respond.badRequest(
              msg: 'Too many files. Maximum allowed: ${config.maxFiles}.');
          return req;
        }

        final partContentType =
            part.headers['content-type'] ?? 'application/octet-stream';

        // MIME type filter.
        if (config.allowedMimeTypes.isNotEmpty &&
            !config.allowedMimeTypes.contains(partContentType)) {
          req.messenger.addError(
              '[readMultipartContent] File type not allowed: $partContentType.');
          req.respond.badRequest(
              msg: 'File type not allowed: $partContentType.',
              errors: <String, Object>{
                'allowedTypes': config.allowedMimeTypes.join(', '),
              });
          return req;
        }

        // Read bytes with size limits.
        final bytesBuilder = BytesBuilder(copy: false);
        var fileSize = 0;

        await for (final chunk in part) {
          fileSize += chunk.length;

          if (fileSize > config.maxFileSize) {
            req.messenger.addError(
                '[readMultipartContent] File "$name" exceeds max size '
                '(${config.maxFileSize} bytes).');
            req.respond.badRequest(
                msg: 'File "$name" exceeds maximum size of '
                    '${_humanSize(config.maxFileSize)}.');
            return req;
          }

          totalSize += chunk.length;
          if (totalSize > config.maxTotalSize) {
            req.messenger.addError(
                '[readMultipartContent] Total upload size exceeds limit '
                '(${config.maxTotalSize} bytes).');
            req.respond.badRequest(
                msg: 'Total upload size exceeds maximum of '
                    '${_humanSize(config.maxTotalSize)}.');
            return req;
          }

          bytesBuilder.add(chunk);
        }

        files.add(UploadedFile(
          fieldName: name,
          filename: filename,
          contentType: partContentType,
          bytes: Uint8List.fromList(bytesBuilder.takeBytes()),
        ));
      } else {
        // — Text field part —
        final value = await utf8.decodeStream(part);
        fields[name] = value;
      }
    }

    req.context.setOrReplace<MultipartFormData>(
      multipartContextKey,
      MultipartFormData(
        fields: Map.unmodifiable(fields),
        files: List.unmodifiable(files),
      ),
    );
  } on MimeMultipartException catch (e) {
    req.messenger
        .addError('[readMultipartContent] Malformed multipart data: $e');
    req.respond.badRequest(msg: 'Malformed multipart request.');
  } catch (e) {
    req.messenger.addError('[readMultipartContent] $e');
    req.respond.badRequest(msg: 'Error parsing multipart request.');
  }

  return req;
}

/// Parse Content-Disposition header parameters.
///
/// Expected format: `form-data; name="fieldname"; filename="file.txt"`
Map<String, String> _parseContentDisposition(String header) {
  final params = <String, String>{};
  final regex = RegExp(r'(\w+)="([^"]*)"');
  for (final match in regex.allMatches(header)) {
    params[match.group(1)!] = match.group(2)!;
  }
  return params;
}

/// Format bytes into human-readable size string.
String _humanSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
