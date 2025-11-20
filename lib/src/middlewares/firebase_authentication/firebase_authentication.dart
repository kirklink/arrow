import 'dart:convert' show json;
import 'dart:io' show CertificateException;
import 'package:http/http.dart' as http;

// import 'package:corsac_jwt/corsac_jwt.dart';
// import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
// import 'package:jaguar_jwt/jaguar_jwt.dart';
// import 'package:jose/jose.dart';
import 'decode.dart';

import 'package:arrow/src/request.dart' show Request;
import 'package:arrow/src/request_middleware.dart';
import 'package:arrow/src/middlewares/firebase_authentication/firebase_token_claims.dart';
// import 'package:arrow/src/config/environment.dart'
//     show EnvironmentInfo;
// import 'package:arrow/src/config/constants.dart' as context
//     show firebaseTokenClaimsContext;

final firebaseCertificateUrl = Uri.parse(
    'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com');

String _issuer(String currentProject) {
  return 'https://securetoken.google.com/${currentProject}';
}

const firebaseDefaultClaimsContextId = '#firebase_default_token_claims';
const firebaseRawClaimsContextId = '#firebase_raw_token_claims';

// String _audience() {
//   return EnvironmentInfo.currentProject;
// }

typedef bool VerifyClaims(Map<String, Object> claims);

// class UnverifiedTokenHeader {
//   final String alg;
//   final String kid;

//   UnverifiedTokenHeader._(this.alg, this.kid);

//   factory UnverifiedTokenHeader(String encoded) {
//     final padded = _base64Padded(encoded);
//     final codec = utf8.fuse(base64);
//     final decoded = codec.decode(padded);
//     final map = json.decode(decoded);
//     return UnverifiedTokenHeader._(map['alg'] as String, map['kid'] as String);
//   }

//   static String _base64Padded(String value) {
//     final lenght = value.length;

//     switch (lenght % 4) {
//       case 2:
//         return value.padRight(lenght + 2, '=');
//       case 3:
//         return value.padRight(lenght + 1, '=');
//       default:
//         return value;
//     }
//   }
// }

class FirebaseCertificate {
  DateTime expiresAt;
  Map<String, String?> certificate;

  FirebaseCertificate._(this.expiresAt, this.certificate);

  factory FirebaseCertificate(
      DateTime expiresAt, Map<String, String?> certificate) {
    _cache = FirebaseCertificate._(expiresAt, certificate);
    return _cache!;
  }

  static bool isValid() =>
      _cache != null &&
      _cache!.expiresAt
          .isAfter(DateTime.now().toUtc().add(Duration(seconds: 1)));
  static FirebaseCertificate? getCertificate() => _cache;

  static FirebaseCertificate? _cache;
}

RequestMiddleware firebaseAuthentication(String gcpProjectName,
    {VerifyClaims? verifier,
    String verifyFailMessage = '',
    bool setDefaultClaimsOnContext = true}) {
  return (Request req) async {
    final authHeader = req.headers.value('Authorization');

    if (authHeader == null) {
      req.respond
          .unauthorized(msg: 'An authorization header was not provided.');
      return req;
    }

    if (!authHeader.startsWith('Bearer ')) {
      req.respond.unauthorized(msg: 'Invalid authorization header format.');
      return req;
    }
    final split = authHeader.split(' ');
    if (split.length != 2) {
      req.respond.unauthorized(
          msg:
              'Invalid authorization header format. Send as "Bearer {TOKEN}".');
      return req;
    }
    final token = split[1];
    final tokenParts = token.split('.');
    if (tokenParts.length != 3) {
      req.respond.unauthorized(
          msg: 'Invalid authorization header format. Not enough jwt segments.');
      return req;
    }

    final decodedToken = JWT.parse(token);

    if (decodedToken.algorithm != 'RS256') {
      req.respond.unauthorized(msg: 'Invalid authorization algorithm.');
      return req;
    }
    final kid = decodedToken.headers['kid'] ?? '';

    if (kid.isEmpty) {
      req.respond.unauthorized(msg: 'Invalid kid claim.');
      return req;
    }

    FirebaseCertificate? certificate;

    // Check if the cached certificate is still valid
    if (FirebaseCertificate.isValid()) {
      certificate = FirebaseCertificate.getCertificate();
    } else {
      final resp = await http.get(firebaseCertificateUrl);

      final cacheControl = resp.headers['cache-control']!;
      final cacheControlParts = cacheControl.split(', ');
      var maxAge = '';
      for (final p in cacheControlParts) {
        if (p.startsWith('max-age=')) {
          maxAge = p;
          continue;
        }
      }
      if (maxAge.isEmpty) {
        throw CertificateException(
            'The certificate was sent without a max-age header.');
      }
      final expirySeconds = int.parse(maxAge.split('=')[1]);
      final expiresAt =
          DateTime.now().toUtc().add(Duration(seconds: expirySeconds));
      final respCerts = json.decode(resp.body) as Map<String, Object>;
      final certs = <String, String?>{};
      for (final k in respCerts.keys) {
        certs[k] = respCerts[k] as String?;
      }
      certificate = FirebaseCertificate(expiresAt, certs);
    }

    try {
      final publicKey = certificate!.certificate[kid]!;
      final signer = JWTRsaSha256Signer(publicKey);
      final isValid = decodedToken.verify(signer);
      if (!isValid) {
        req.respond.unauthorized(msg: 'The jwt token was not valid.');
        return req;
      }
    } catch (e) {
      req.respond.unauthorized(msg: 'An unknown authorization error occurred.');
      return req;
    }

    if (decodedToken.expiresAt <=
        DateTime.now().millisecondsSinceEpoch / 1000) {
      req.respond.unauthorized(msg: 'Invalid exp claim.');
      return req;
    }
    if (decodedToken.issuedAt >= DateTime.now().millisecondsSinceEpoch / 1000) {
      req.respond.unauthorized(msg: 'Invalid iat claim.');
      return req;
    }
    if (decodedToken.audience != gcpProjectName) {
      req.respond.unauthorized(msg: 'Invalid aud claim.');
      return req;
    }
    if (decodedToken.issuer != _issuer(gcpProjectName)) {
      req.respond.unauthorized(msg: 'Invalid iss claim.');
      return req;
    }
    if (decodedToken.subject.isEmpty) {
      req.respond.unauthorized(msg: 'Invalid sub claim.');
      return req;
    }
    if (decodedToken.claims['auth_time'] >=
        DateTime.now().millisecondsSinceEpoch / 1000) {
      req.respond.unauthorized(msg: 'Invalid iat claim.');
      return req;
    }

    // To here the jwt token is valid
    // Now look at the claims

    // If previously verified, good to pass through
    // See if a verifier was provided
    if (verifier != null) {
      if (verifier(decodedToken.claims as Map<String, Object>) == false) {
        final failMessage = verifyFailMessage.isNotEmpty
            ? verifyFailMessage
            : 'The claims were not valid.';
        req.respond.unauthorized(msg: failMessage);
        return req;
      }
    }

    req.context.trySet(firebaseRawClaimsContextId, decodedToken.claims);

    if (setDefaultClaimsOnContext) {
      final claims = FirebaseTokenClaims.fromJson(decodedToken.claims as Map<String, Object>);
      req.context
          .trySet<FirebaseTokenClaims>(firebaseDefaultClaimsContextId, claims);
    }

    return req;
  };
}
