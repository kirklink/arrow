import 'uploaded_file.dart';
import 'request.dart';
import 'context.dart';

/// Well-known context key for storing MultipartFormData.
final multipartContextKey = Context.makeKey();

/// Parsed result of a multipart/form-data request.
///
/// Contains both text fields and uploaded files extracted from the
/// multipart body. Access via [MultipartFormData.of] after applying
/// the [readMultipartContent] middleware.
///
/// ```dart
/// router.post('/upload', (req) async {
///   final form = MultipartFormData.of(req)!;
///   final description = form.field('description');
///   final file = form.file('document');
///   // ...
/// });
/// ```
class MultipartFormData {
  /// Text form fields as name-value pairs.
  ///
  /// For repeated field names, the last value wins.
  final Map<String, String> fields;

  /// All uploaded files, in the order they appeared in the request.
  final List<UploadedFile> files;

  const MultipartFormData({
    this.fields = const <String, String>{},
    this.files = const <UploadedFile>[],
  });

  /// Get a single text field value by name.
  ///
  /// Returns `null` if the field is not present.
  String? field(String name) => fields[name];

  /// Get a single uploaded file by field name.
  ///
  /// Returns the first file matching [fieldName], or `null` if none.
  UploadedFile? file(String fieldName) {
    for (final f in files) {
      if (f.fieldName == fieldName) return f;
    }
    return null;
  }

  /// Get all uploaded files for a given field name.
  ///
  /// Useful for `<input type="file" multiple>` fields.
  List<UploadedFile> filesFor(String fieldName) {
    return files.where((f) => f.fieldName == fieldName).toList();
  }

  /// Retrieve [MultipartFormData] from [req.context].
  ///
  /// Returns `null` if the [readMultipartContent] middleware has not run
  /// or the request was not multipart.
  ///
  /// ```dart
  /// final form = MultipartFormData.of(req);
  /// if (form == null) throw BadRequestException('Expected multipart upload');
  /// ```
  static MultipartFormData? of(Request req) {
    return req.context.tryGet<MultipartFormData>(multipartContextKey);
  }
}
