import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:rsa_pkcs/rsa_pkcs.dart' as rsa;

// From corsac_jwt

int secondsSinceEpoch(DateTime dateTime) =>
    (dateTime.millisecondsSinceEpoch / 1000).floor();

final _logger = Logger('JWTRsaSha256Signer');

class JWTRsaSha256Signer {
  rsa.RSAPublicKey? _publicKey;

  /// Creates new signer.
  JWTRsaSha256Signer(String publicKey) {
    final parser = rsa.RSAPKCSParser();

    final pair = parser.parsePEM(publicKey);
    if (pair.public is! rsa.RSAPublicKey) {
      throw JWTError('Invalid public RSA key.');
    }
    _publicKey = pair.public;
  }

  String get algorithm => 'RS256';

  bool verify(List<int> body, List<int> signature) {
    if (_publicKey == null) {
      throw StateError(
          'RS256 signer requires public key to verify signatures.');
    }

    try {
      final s = Signer('SHA-256/RSA');
      final key = RSAPublicKey(
          _publicKey!.modulus, BigInt.from(_publicKey!.publicExponent));
      final param = ParametersWithRandom(
        PublicKeyParameter<RSAPublicKey>(key),
        SecureRandom('AES/CTR/PRNG'),
      );

      s.init(false, param);
      final rsaSignature = RSASignature(Uint8List.fromList(signature));
      return s.verifySignature(Uint8List.fromList(body), rsaSignature);
    } catch (e) {
      _logger.warning(
          'RS256 token verification failed with following error: $e.', e);
      return false;
    }
  }
}

Map<String, T> _decode<T>(String input) {
  try {
    return Map.from(
      _jsonToBase64Url.decode(_base64Padded(input)) as Map<String, dynamic>,
    );
  } catch (e) {
    throw JWTError('Could not decode token string. Error: $e.');
  }
}

final _jsonToBase64Url = json.fuse(utf8.fuse(base64Url));

String _base64Padded(String value) {
  final mod = value.length % 4;
  if (mod == 0) {
    return value;
  } else if (mod == 3) {
    return value.padRight(value.length + 1, '=');
  } else if (mod == 2) {
    return value.padRight(value.length + 2, '=');
  } else {
    return value; // let it fail when decoding
  }
}

/// Error thrown by `JWT` when parsing tokens from string.
class JWTError implements Exception {
  final String message;

  JWTError(this.message);

  @override
  String toString() => 'JWTError: $message';
}

/// JSON Web Token.
class JWT {
  /// List of standard (reserved) claims.
  static const reservedClaims = [
    'iss',
    'aud',
    'iat',
    'exp',
    'nbf',
    'sub',
    'jti'
  ];

  /// List of reserved headers.
  static const reservedHeaders = ['typ', 'alg'];

  /// Allows access to the full headers map.
  ///
  /// Returned map is read-only.
  final Map<String, String> headers;

  /// Allows access to the full claims map.
  ///
  /// Returns modifiable copy of internal map object.
  Map<String, dynamic> get claims => Map.from(_claims);
  final Map<String, dynamic> _claims;

  /// Contains original Base64 encoded token header.
  final String encodedHeader;

  /// Contains original Base64 encoded token payload (claims).
  final String encodedPayload;

  /// Contains original Base64 encoded token signature, or `null`
  /// if token is unsigned.
  final String? signature;

  JWT._(this.encodedHeader, this.encodedPayload, this.signature)
      : headers = Map.unmodifiable(_decode(encodedHeader)),
        _claims = _decode(encodedPayload);

  /// Parses [token] string and creates new instance of [JWT].
  /// Throws [JWTError] if parsing fails.
  factory JWT.parse(String token) {
    final parts = token.split('.');
    if (parts.length == 2) {
      return JWT._(parts.first, parts.last, null);
    } else if (parts.length == 3) {
      return JWT._(parts[0], parts[1], parts[2]);
    } else {
      throw JWTError('Invalid token string format for JWT.');
    }
  }

  /// Algorithm used to sign this token. The value `none` means this token
  /// is not signed.
  ///
  /// One should not rely on this value to determine the algorithm used to sign
  /// this token.
  String get algorithm => headers['alg'] ?? '';

  /// The issuer of this token (value of standard `iss` claim).
  String get issuer => _claims['iss'] as String? ?? '';

  /// The audience of this token (value of standard `aud` claim).
  String get audience => _claims['aud'] as String? ?? '';

  /// The time this token was issued (value of standard `iat` claim).
  int get issuedAt => _claims['iat'] as int? ?? 0;

  /// The expiration time of this token (value of standard `exp` claim).
  int get expiresAt => _claims['exp'] as int? ?? 0;

  /// The time before which this token must not be accepted (value of standard
  /// `nbf` claim).
  int get notBefore => _claims['nbf'] as int? ?? 0;

  /// Identifies the principal that is the subject of this token (value of
  /// standard `sub` claim).
  String get subject => _claims['sub'] as String? ?? '';

  /// Unique identifier of this token (value of standard `jti` claim).
  String get id => _claims['jti'] as String? ?? '';

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeAll([encodedHeader, '.', encodedPayload]);
    if (signature is String) {
      buffer.writeAll(['.', signature]);
    }
    return buffer.toString();
  }

  /// Verifies this token's signature using [signer].
  ///
  /// Returns `true` if signature is valid and `false` otherwise.
  bool verify(JWTRsaSha256Signer signer) {
    final body = utf8.encode('$encodedHeader.$encodedPayload');
    final sign = base64Url.decode(_base64Padded(signature!));
    return signer.verify(body, sign);
  }

  /// Returns value associated with claim specified by [key].
  dynamic getClaim(String key) => _claims[key];
}
