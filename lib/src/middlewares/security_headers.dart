import '../request.dart';
import '../request_middleware.dart';

/// Configuration for security response headers.
///
/// All fields default to secure values appropriate for REST APIs.
/// Set any field to `null` to disable that header.
///
/// ```dart
/// // Use all defaults
/// router.onRequest(securityHeaders());
///
/// // Override specific headers
/// router.onRequest(securityHeaders(SecurityHeadersConfig(
///   frameOptions: 'SAMEORIGIN',
///   strictTransportSecurity: 'max-age=31536000',
/// )));
///
/// // Disable a header
/// router.onRequest(securityHeaders(SecurityHeadersConfig(
///   contentSecurityPolicy: null,
/// )));
/// ```
class SecurityHeadersConfig {
  /// `X-Content-Type-Options` — prevents MIME type sniffing.
  final String? contentTypeOptions;

  /// `X-Frame-Options` — controls whether the response can be framed.
  final String? frameOptions;

  /// `Strict-Transport-Security` — enforces HTTPS connections.
  final String? strictTransportSecurity;

  /// `Referrer-Policy` — controls the Referer header sent with requests.
  final String? referrerPolicy;

  /// `X-XSS-Protection` — legacy XSS filter control. Set to `0` (disabled)
  /// per modern best practice; rely on Content-Security-Policy instead.
  final String? xssProtection;

  /// `Content-Security-Policy` — restricts resource loading.
  /// Default `default-src 'none'` is strict and appropriate for JSON APIs.
  final String? contentSecurityPolicy;

  /// `Cross-Origin-Resource-Policy` — prevents cross-origin resource leaks.
  final String? crossOriginResourcePolicy;

  const SecurityHeadersConfig({
    this.contentTypeOptions = 'nosniff',
    this.frameOptions = 'DENY',
    this.strictTransportSecurity = 'max-age=15552000; includeSubDomains',
    this.referrerPolicy = 'no-referrer',
    this.xssProtection = '0',
    this.contentSecurityPolicy = "default-src 'none'",
    this.crossOriginResourcePolicy = 'same-origin',
  });
}

/// Middleware that sets security response headers.
///
/// Uses [RequestMiddleware] so headers are set before the handler runs,
/// ensuring they are present even on error responses (HttpException).
///
/// ```dart
/// return Router()
///   ..onRequest(securityHeaders())
///   ..get('/health', healthCheck);
/// ```
RequestMiddleware securityHeaders(
    [SecurityHeadersConfig config = const SecurityHeadersConfig()]) {
  // Build the header map once at registration time, not per-request.
  final headerMap = <String, String?>{
    'X-Content-Type-Options': config.contentTypeOptions,
    'X-Frame-Options': config.frameOptions,
    'Strict-Transport-Security': config.strictTransportSecurity,
    'Referrer-Policy': config.referrerPolicy,
    'X-XSS-Protection': config.xssProtection,
    'Content-Security-Policy': config.contentSecurityPolicy,
    'Cross-Origin-Resource-Policy': config.crossOriginResourcePolicy,
  };

  return (Request req) async {
    final headers = req.innerRequest.response.headers;
    headerMap.forEach((name, value) {
      if (value != null) {
        headers.set(name, value);
      } else {
        headers.removeAll(name);
      }
    });
    return req;
  };
}
