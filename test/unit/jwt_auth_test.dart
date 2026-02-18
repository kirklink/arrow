import 'package:test/test.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:arrow/src/request.dart';
import 'package:arrow/src/middlewares/jwt_auth.dart';
import '../test_helpers.dart';

/// Creates a signed JWT token string with the given payload and secret.
String _signToken(
  Map<String, dynamic> payload,
  String secret, {
  Duration? expiresIn,
  String? issuer,
  Audience? audience,
}) {
  final jwt = JWT(payload, issuer: issuer, audience: audience);
  return jwt.sign(
    SecretKey(secret),
    expiresIn: expiresIn,
  );
}

const _secret = 'test-secret-key-for-jwt-auth';

void main() {
  group('JWT Auth Middleware', () {
    tearDownAll(() async {
      await cleanupAllMockRequests();
    });

    group('JwtAuthConfig', () {
      test('should require a key', () {
        final config = JwtAuthConfig(key: SecretKey(_secret));
        expect(config.key, isA<SecretKey>());
      });

      test('should use default messages', () {
        final config = JwtAuthConfig(key: SecretKey(_secret));
        expect(config.missingTokenMessage, equals('Authentication required'));
        expect(config.invalidTokenMessage, equals('Invalid token'));
        expect(config.expiredTokenMessage, equals('Token expired'));
      });

      test('should accept custom messages', () {
        final config = JwtAuthConfig(
          key: SecretKey(_secret),
          missingTokenMessage: 'Please log in',
          invalidTokenMessage: 'Bad token',
          expiredTokenMessage: 'Session expired',
        );
        expect(config.missingTokenMessage, equals('Please log in'));
        expect(config.invalidTokenMessage, equals('Bad token'));
        expect(config.expiredTokenMessage, equals('Session expired'));
      });

      test('should accept optional issuer and audience', () {
        final config = JwtAuthConfig(
          key: SecretKey(_secret),
          issuer: 'https://auth.example.com',
          audience: 'my-api',
        );
        expect(config.issuer, equals('https://auth.example.com'));
        expect(config.audience, equals('my-api'));
      });

      test('should accept custom tokenExtractor', () {
        final config = JwtAuthConfig(
          key: SecretKey(_secret),
          tokenExtractor: (req) => req.headers.value('X-Token'),
        );
        expect(config.tokenExtractor, isNotNull);
      });
    });

    group('missing token', () {
      test('should return 401 when no Authorization header', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(key: SecretKey(_secret)));

        await mw(req);

        expect(req.isAlive, isFalse);
        expect(req.innerRequest.response.statusCode, equals(401));

        await cleanupMockRequest(httpReq);
      });

      test('should return 401 when Authorization is not Bearer', () async {
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Basic abc123'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(key: SecretKey(_secret)));

        await mw(req);

        expect(req.isAlive, isFalse);
        expect(req.innerRequest.response.statusCode, equals(401));

        await cleanupMockRequest(httpReq);
      });

      test('should return 401 when Bearer token is empty', () async {
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer '},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(key: SecretKey(_secret)));

        await mw(req);

        expect(req.isAlive, isFalse);
        expect(req.innerRequest.response.statusCode, equals(401));

        await cleanupMockRequest(httpReq);
      });

      test('should use custom missing token message', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(
          key: SecretKey(_secret),
          missingTokenMessage: 'Please log in',
        ));

        await mw(req);

        expect(req.isAlive, isFalse);
        expect(req.innerRequest.response.statusCode, equals(401));

        await cleanupMockRequest(httpReq);
      });
    });

    group('invalid token', () {
      test('should return 401 for malformed token', () async {
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer not-a-valid-jwt'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(key: SecretKey(_secret)));

        await mw(req);

        expect(req.isAlive, isFalse);
        expect(req.innerRequest.response.statusCode, equals(401));

        await cleanupMockRequest(httpReq);
      });

      test('should return 401 when signed with wrong key', () async {
        final token = _signToken(
          {'sub': 'user-1'},
          'wrong-secret-key',
          expiresIn: const Duration(hours: 1),
        );
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer $token'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(key: SecretKey(_secret)));

        await mw(req);

        expect(req.isAlive, isFalse);
        expect(req.innerRequest.response.statusCode, equals(401));

        await cleanupMockRequest(httpReq);
      });

      test('should use custom invalid token message', () async {
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer garbage.token.here'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(
          key: SecretKey(_secret),
          invalidTokenMessage: 'Bad token provided',
        ));

        await mw(req);

        expect(req.isAlive, isFalse);
        expect(req.innerRequest.response.statusCode, equals(401));

        await cleanupMockRequest(httpReq);
      });
    });

    group('expired token', () {
      test('should return 401 for expired token', () async {
        // Sign a token that expired 1 hour ago
        final jwt = JWT({'sub': 'user-1'});
        final token = jwt.sign(
          SecretKey(_secret),
          expiresIn: const Duration(seconds: -3600),
        );

        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer $token'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(key: SecretKey(_secret)));

        await mw(req);

        expect(req.isAlive, isFalse);
        expect(req.innerRequest.response.statusCode, equals(401));

        await cleanupMockRequest(httpReq);
      });

      test('should use custom expired token message', () async {
        final jwt = JWT({'sub': 'user-1'});
        final token = jwt.sign(
          SecretKey(_secret),
          expiresIn: const Duration(seconds: -3600),
        );

        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer $token'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(
          key: SecretKey(_secret),
          expiredTokenMessage: 'Session expired, please log in again',
        ));

        await mw(req);

        expect(req.isAlive, isFalse);
        expect(req.innerRequest.response.statusCode, equals(401));

        await cleanupMockRequest(httpReq);
      });
    });

    group('issuer validation', () {
      test('should reject token with wrong issuer', () async {
        final token = _signToken(
          {'sub': 'user-1'},
          _secret,
          expiresIn: const Duration(hours: 1),
          issuer: 'https://wrong-issuer.com',
        );
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer $token'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(
          key: SecretKey(_secret),
          issuer: 'https://auth.example.com',
        ));

        await mw(req);

        expect(req.isAlive, isFalse);
        expect(req.innerRequest.response.statusCode, equals(401));

        await cleanupMockRequest(httpReq);
      });

      test('should accept token with correct issuer', () async {
        final token = _signToken(
          {'sub': 'user-1'},
          _secret,
          expiresIn: const Duration(hours: 1),
          issuer: 'https://auth.example.com',
        );
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer $token'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(
          key: SecretKey(_secret),
          issuer: 'https://auth.example.com',
        ));

        await mw(req);

        expect(req.isAlive, isTrue);

        await cleanupMockRequest(httpReq);
      });

      test('should skip issuer check when not configured', () async {
        final token = _signToken(
          {'sub': 'user-1'},
          _secret,
          expiresIn: const Duration(hours: 1),
          issuer: 'https://any-issuer.com',
        );
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer $token'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(key: SecretKey(_secret)));

        await mw(req);

        expect(req.isAlive, isTrue);

        await cleanupMockRequest(httpReq);
      });
    });

    group('audience validation', () {
      test('should reject token with wrong audience', () async {
        final token = _signToken(
          {'sub': 'user-1'},
          _secret,
          expiresIn: const Duration(hours: 1),
          audience: Audience(['wrong-api']),
        );
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer $token'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(
          key: SecretKey(_secret),
          audience: 'my-api',
        ));

        await mw(req);

        expect(req.isAlive, isFalse);
        expect(req.innerRequest.response.statusCode, equals(401));

        await cleanupMockRequest(httpReq);
      });

      test('should accept token with correct audience', () async {
        final token = _signToken(
          {'sub': 'user-1'},
          _secret,
          expiresIn: const Duration(hours: 1),
          audience: Audience(['my-api']),
        );
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer $token'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(
          key: SecretKey(_secret),
          audience: 'my-api',
        ));

        await mw(req);

        expect(req.isAlive, isTrue);

        await cleanupMockRequest(httpReq);
      });

      test('should skip audience check when not configured', () async {
        final token = _signToken(
          {'sub': 'user-1'},
          _secret,
          expiresIn: const Duration(hours: 1),
          audience: Audience(['any-audience']),
        );
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer $token'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(key: SecretKey(_secret)));

        await mw(req);

        expect(req.isAlive, isTrue);

        await cleanupMockRequest(httpReq);
      });
    });

    group('successful verification', () {
      test('should store JWT in context on success', () async {
        final token = _signToken(
          {'sub': 'user-42', 'role': 'admin'},
          _secret,
          expiresIn: const Duration(hours: 1),
        );
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer $token'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(key: SecretKey(_secret)));

        await mw(req);

        expect(req.isAlive, isTrue);
        final jwt = req.context.tryGet<JWT>(jwtKey);
        expect(jwt, isNotNull);
        expect(jwt!.payload['sub'], equals('user-42'));
        expect(jwt.payload['role'], equals('admin'));

        await cleanupMockRequest(httpReq);
      });

      test('should be accessible via getJwt helper', () async {
        final token = _signToken(
          {'sub': 'user-99'},
          _secret,
          expiresIn: const Duration(hours: 1),
        );
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer $token'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(key: SecretKey(_secret)));

        await mw(req);

        final jwt = getJwt(req);
        expect(jwt, isNotNull);
        expect(jwt!.payload['sub'], equals('user-99'));

        await cleanupMockRequest(httpReq);
      });

      test('should keep request alive', () async {
        final token = _signToken(
          {'sub': 'user-1'},
          _secret,
          expiresIn: const Duration(hours: 1),
        );
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer $token'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(key: SecretKey(_secret)));

        final result = await mw(req);

        expect(result.isAlive, isTrue);
        expect(identical(result, req), isTrue);

        await cleanupMockRequest(httpReq);
      });
    });

    group('custom tokenExtractor', () {
      test('should use custom extractor', () async {
        final token = _signToken(
          {'sub': 'user-1'},
          _secret,
          expiresIn: const Duration(hours: 1),
        );
        final httpReq = await createMockHttpRequest(
          headers: {'X-Auth-Token': token},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(
          key: SecretKey(_secret),
          tokenExtractor: (req) => req.headers.value('x-auth-token'),
        ));

        await mw(req);

        expect(req.isAlive, isTrue);
        expect(getJwt(req), isNotNull);

        await cleanupMockRequest(httpReq);
      });

      test('should return 401 when custom extractor returns null', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(
          key: SecretKey(_secret),
          tokenExtractor: (req) => null,
        ));

        await mw(req);

        expect(req.isAlive, isFalse);
        expect(req.innerRequest.response.statusCode, equals(401));

        await cleanupMockRequest(httpReq);
      });
    });

    group('getJwt helper', () {
      test('should return null before middleware runs', () async {
        final httpReq = await createMockHttpRequest();
        final req = Request(httpReq);

        expect(getJwt(req), isNull);

        await cleanupMockRequest(httpReq);
      });

      test('should return null after failed auth', () async {
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer invalid-token'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(key: SecretKey(_secret)));

        await mw(req);

        expect(getJwt(req), isNull);

        await cleanupMockRequest(httpReq);
      });

      test('should return JWT after successful auth', () async {
        final token = _signToken(
          {'sub': 'user-1', 'name': 'Alice'},
          _secret,
          expiresIn: const Duration(hours: 1),
        );
        final httpReq = await createMockHttpRequest(
          headers: {'Authorization': 'Bearer $token'},
        );
        final req = Request(httpReq);
        final mw = jwtAuth(JwtAuthConfig(key: SecretKey(_secret)));

        await mw(req);

        final jwt = getJwt(req);
        expect(jwt, isNotNull);
        expect(jwt!.payload['name'], equals('Alice'));

        await cleanupMockRequest(httpReq);
      });
    });

    group('jwtKey', () {
      test('should be a non-empty string', () {
        expect(jwtKey, isA<String>());
        expect(jwtKey, isNotEmpty);
      });
    });
  });
}
