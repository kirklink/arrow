/// JWT utilities for Arrow.
///
/// Re-exports key types from `dart_jsonwebtoken` alongside Arrow's
/// JWT middleware helpers so consuming packages do not need a
/// separate dependency on `dart_jsonwebtoken`.
///
/// ```dart
/// import 'package:arrow/jwt.dart';
///
/// // Sign a token (in a login handler)
/// final jwt = JWT({'sub': userId, 'role': 'admin'});
/// final token = jwt.sign(SecretKey('secret'), expiresIn: Duration(hours: 1));
///
/// // Verify (done automatically by jwtAuth middleware)
/// final jwt = JWT.verify(token, SecretKey('secret'));
/// ```
library jwt;

export 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart'
    show
        JWT,
        JWTKey,
        SecretKey,
        RSAPublicKey,
        RSAPrivateKey,
        ECPublicKey,
        ECPrivateKey,
        EdDSAPublicKey,
        EdDSAPrivateKey,
        JWTException,
        JWTExpiredException,
        JWTAlgorithm,
        Audience;

export 'src/middlewares/jwt_auth.dart' show jwtAuth, JwtAuthConfig, jwtKey, getJwt;
