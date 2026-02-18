import 'dart:typed_data';

/// Represents a single uploaded file from a multipart/form-data request.
///
/// Contains the file's metadata (field name, filename, content type) and
/// the raw bytes buffered in memory.
///
/// ```dart
/// final form = MultipartFormData.of(req)!;
/// final avatar = form.file('avatar');
/// if (avatar != null) {
///   print('Received ${avatar.filename}, ${avatar.size} bytes');
///   await File('uploads/${avatar.filename}').writeAsBytes(avatar.bytes);
/// }
/// ```
class UploadedFile {
  /// The form field name (from Content-Disposition `name` parameter).
  final String fieldName;

  /// The original filename provided by the client.
  ///
  /// May be empty if the client did not provide a filename.
  /// **Warning:** Never trust this value for filesystem paths without
  /// sanitizing it first. Clients can send arbitrary strings.
  final String filename;

  /// The MIME type of the file (from the part's Content-Type header).
  ///
  /// Defaults to `'application/octet-stream'` if not provided by the client.
  final String contentType;

  /// The raw file bytes, buffered in memory.
  final Uint8List bytes;

  /// The file size in bytes.
  int get size => bytes.length;

  UploadedFile({
    required this.fieldName,
    required this.filename,
    required this.contentType,
    required this.bytes,
  });

  @override
  String toString() =>
      'UploadedFile($fieldName, $filename, $contentType, $size bytes)';
}
