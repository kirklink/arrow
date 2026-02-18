/// Type-safe MIME type representation with lookup by file extension.
///
/// Provides static constants for common MIME types and a [fromPath]
/// factory for automatic detection based on file extension.
///
/// ```dart
/// // Use constants directly
/// response.headers.set('Content-Type', MimeType.html.value);
///
/// // Lookup by file path
/// final type = MimeType.fromPath('style.css'); // MimeType.css
/// ```
class MimeType {
  /// The full MIME type string (e.g., `'text/html; charset=utf-8'`).
  final String value;

  const MimeType(this.value);

  // — Text types (with charset) —

  static const html = MimeType('text/html; charset=utf-8');
  static const css = MimeType('text/css; charset=utf-8');
  static const javascript = MimeType('application/javascript; charset=utf-8');
  static const json = MimeType('application/json; charset=utf-8');
  static const xml = MimeType('application/xml; charset=utf-8');
  static const text = MimeType('text/plain; charset=utf-8');
  static const csv = MimeType('text/csv; charset=utf-8');
  static const svg = MimeType('image/svg+xml; charset=utf-8');
  static const markdown = MimeType('text/markdown; charset=utf-8');
  static const yaml = MimeType('text/yaml; charset=utf-8');

  // — Image types —

  static const png = MimeType('image/png');
  static const jpg = MimeType('image/jpeg');
  static const gif = MimeType('image/gif');
  static const webp = MimeType('image/webp');
  static const ico = MimeType('image/x-icon');
  static const bmp = MimeType('image/bmp');
  static const avif = MimeType('image/avif');

  // — Font types —

  static const woff = MimeType('font/woff');
  static const woff2 = MimeType('font/woff2');
  static const ttf = MimeType('font/ttf');
  static const otf = MimeType('font/otf');
  static const eot = MimeType('application/vnd.ms-fontobject');

  // — Audio/Video types —

  static const mp3 = MimeType('audio/mpeg');
  static const mp4 = MimeType('video/mp4');
  static const webm = MimeType('video/webm');
  static const ogg = MimeType('audio/ogg');
  static const wav = MimeType('audio/wav');

  // — Application types —

  static const pdf = MimeType('application/pdf');
  static const zip = MimeType('application/zip');
  static const gzip = MimeType('application/gzip');
  static const tar = MimeType('application/x-tar');
  static const wasm = MimeType('application/wasm');
  static const octetStream = MimeType('application/octet-stream');

  /// Fallback type for unknown extensions.
  static const fallback = octetStream;

  static const _byExtension = <String, MimeType>{
    '.html': html,
    '.htm': html,
    '.css': css,
    '.js': javascript,
    '.mjs': javascript,
    '.json': json,
    '.xml': xml,
    '.txt': text,
    '.csv': csv,
    '.svg': svg,
    '.md': markdown,
    '.yaml': yaml,
    '.yml': yaml,
    '.png': png,
    '.jpg': jpg,
    '.jpeg': jpg,
    '.gif': gif,
    '.webp': webp,
    '.ico': ico,
    '.bmp': bmp,
    '.avif': avif,
    '.woff': woff,
    '.woff2': woff2,
    '.ttf': ttf,
    '.otf': otf,
    '.eot': eot,
    '.mp3': mp3,
    '.mp4': mp4,
    '.webm': webm,
    '.ogg': ogg,
    '.wav': wav,
    '.pdf': pdf,
    '.zip': zip,
    '.gz': gzip,
    '.tar': tar,
    '.wasm': wasm,
  };

  /// Look up a [MimeType] from a file path or filename.
  ///
  /// Extracts the extension and returns the matching type,
  /// or [fallback] (`application/octet-stream`) for unknown extensions.
  ///
  /// ```dart
  /// MimeType.fromPath('index.html')      // MimeType.html
  /// MimeType.fromPath('/css/style.css')   // MimeType.css
  /// MimeType.fromPath('data.unknown')     // MimeType.fallback
  /// ```
  static MimeType fromPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return fallback;
    final ext = path.substring(dot).toLowerCase();
    return _byExtension[ext] ?? fallback;
  }

  @override
  String toString() => value;
}
