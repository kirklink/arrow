import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../context.dart';
import '../request.dart';
import '../request_middleware.dart';

/// Context key for the verified [JWT].
///
/// Use with `req.context.tryGet<JWT>(jwtKey)` or the convenience
/// helper [getJwt].
final jwtKey = Context.makeKey();

/// Retrieve the verified [JWT] from the request context.
///
/// Returns `null` if the [jwtAuth] middleware has not run or
/// the token failed verification.
///
/// ```dart
/// final jwt = getJwt(req);
/// if (jwt != null) {
///   print(jwt.payload); // Map<String, dynamic>
///   print(jwt.subject);
/// }
/// ```
JWT? getJwt(Request req) {
  return req.context.tryGet<JWT>(jwtKey);
}

/// Configuration for the [jwtAuth] middleware.
///
/// ```dart
/// router.onRequest(jwtAuth(JwtAuthConfig(
///   key: SecretKey('my-secret'),
///   issuer: 'https://auth.example.com',
///   audience: 'my-api',
/// )));
/// ```
class JwtAuthConfig {
  /// The key used to verify JWT signatures.
  ///
  /// Accepts any [JWTKey] from dart_jsonwebtoken:
  /// - [SecretKey] for HMAC (HS256/HS384/HS512)
  /// - [RSAPublicKey] for RSA (RS256/RS384/RS512)
  /// - [ECPublicKey] for ECDSA (ES256/ES384/ES512)
  /// - [EdDSAPublicKey] for EdDSA
  final JWTKey key;

  /// Expected issuer (`iss` claim). Tokens with a different issuer
  /// are rejected with 401.
  final String? issuer;

  /// Expected audience (`aud` claim). Tokens not intended for this
  /// audience are rejected with 401.
  final String? audience;

  /// Custom function to extract the token string from the request.
  ///
  /// Defaults to reading `Authorization: Bearer <token>`.
  /// Return `null` to signal "no token present" (triggers 401).
  final String? Function(Request req)? tokenExtractor;

  /// 401 message when no token is present.
  final String missingTokenMessage;

  /// 401 message when the token is invalid (bad signature, format, claims).
  final String invalidTokenMessage;

  /// 401 message when the token has expired.
  final String expiredTokenMessage;

  JwtAuthConfig({
    required this.key,
    this.issuer,
    this.audience,
    this.tokenExtractor,
    this.missingTokenMessage = 'Authentication required',
    this.invalidTokenMessage = 'Invalid token',
    this.expiredTokenMessage = 'Token expired',
  });
}

String? _defaultTokenExtractor(Request req) {
  final header = req.headers.value('authorization');
  if (header == null || !header.startsWith('Bearer ')) return null;
  final token = header.substring(7).trim();
  return token.isEmpty ? null : token;
}

/// JWT authentication middleware.
///
/// Verifies the JWT from the `Authorization: Bearer <token>` header
/// (or a custom [JwtAuthConfig.tokenExtractor]) and stores the decoded
/// [JWT] in the request context under [jwtKey].
///
/// On failure, responds with 401 Unauthorized and cancels the pipeline.
///
/// ```dart
/// // Global auth
/// router.onRequest(jwtAuth(JwtAuthConfig(
///   key: SecretKey('my-secret'),
/// )));
///
/// // Per-route auth
/// router.get('/admin/dashboard', adminHandler)
///   ..addOnRequest(jwtAuth(JwtAuthConfig(
///     key: SecretKey('secret'),
///     audience: 'admin-panel',
///   )));
/// ```
RequestMiddleware jwtAuth(JwtAuthConfig config) {
  final extractToken = config.tokenExtractor ?? _defaultTokenExtractor;

  return (Request req) async {
    final token = extractToken(req);
    if (token == null) {
      req.respond.unauthorized(msg: config.missingTokenMessage);
      return req;
    }

    try {
      final jwt = JWT.verify(
        token,
        config.key,
        issuer: config.issuer,
        audience:
            config.audience != null ? Audience([config.audience!]) : null,
      );
      req.context.setOrReplace<JWT>(jwtKey, jwt);
    } on JWTExpiredException {
      req.respond.unauthorized(msg: config.expiredTokenMessage);
    } on JWTException {
      req.respond.unauthorized(msg: config.invalidTokenMessage);
    }

    return req;
  };
}
