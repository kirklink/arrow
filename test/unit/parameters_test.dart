import 'package:test/test.dart';
import 'package:arrow/src/parameters.dart';

void main() {
  group('Parameters', () {
    test('should start empty', () {
      final params = Parameters();

      expect(params.get('any-key'), equals(''));
    });

    test('should return empty string for non-existent keys', () {
      final params = Parameters();

      expect(params.get('missing'), equals(''));
      expect(params.get('nonexistent'), equals(''));
    });

    group('load()', () {
      test('should load parameters from map', () {
        final params = Parameters();

        params.load({'id': '123', 'name': 'Alice'});

        expect(params.get('id'), equals('123'));
        expect(params.get('name'), equals('Alice'));
      });

      test('should load empty map', () {
        final params = Parameters();

        params.load({});

        expect(params.get('any-key'), equals(''));
      });

      test('should handle URL-like parameters', () {
        final params = Parameters();

        params.load({
          'userId': '42',
          'postId': '789',
          'slug': 'hello-world',
        });

        expect(params.get('userId'), equals('42'));
        expect(params.get('postId'), equals('789'));
        expect(params.get('slug'), equals('hello-world'));
      });

      test('should throw ParametersException if already loaded', () {
        final params = Parameters();

        params.load({'first': 'load'});

        expect(
          () => params.load({'second': 'load'}),
          throwsA(isA<ParametersException>()),
        );
      });

      test('should throw even if second load is empty', () {
        final params = Parameters();

        params.load({'key': 'value'});

        expect(
          () => params.load({}),
          throwsA(isA<ParametersException>()),
        );
      });

      test('should preserve loaded values after throw', () {
        final params = Parameters();

        params.load({'original': 'value'});

        try {
          params.load({'new': 'value'});
        } catch (e) {
          // Expected
        }

        expect(params.get('original'), equals('value'));
        expect(params.get('new'), equals('')); // Not loaded
      });
    });

    group('get()', () {
      test('should return exact string values', () {
        final params = Parameters();

        params.load({
          'simple': 'value',
          'number': '12345',
          'special': 'hello-world_123',
        });

        expect(params.get('simple'), equals('value'));
        expect(params.get('number'), equals('12345'));
        expect(params.get('special'), equals('hello-world_123'));
      });

      test('should return empty string, not null', () {
        final params = Parameters();

        params.load({'exists': 'value'});

        final result = params.get('missing');

        expect(result, isNotNull);
        expect(result, equals(''));
        expect(result, isNot(isNull));
      });

      test('should distinguish between empty and missing', () {
        final params = Parameters();

        params.load({'empty': '', 'present': 'value'});

        expect(params.get('empty'), equals(''));
        expect(params.get('missing'), equals(''));
        expect(params.get('present'), equals('value'));
      });

      test('should handle special characters', () {
        final params = Parameters();

        params.load({
          'path': '/users/123',
          'query': 'name=Alice&age=30',
          'encoded': 'hello%20world',
        });

        expect(params.get('path'), equals('/users/123'));
        expect(params.get('query'), equals('name=Alice&age=30'));
        expect(params.get('encoded'), equals('hello%20world'));
      });
    });

    group('ParametersException', () {
      test('should be catchable as Exception', () {
        expect(
          () => throw ParametersException('Test error'),
          throwsA(isA<Exception>()),
        );
      });

      test('should contain cause message', () {
        final exception = ParametersException('Custom message');

        expect(exception.cause, equals('Custom message'));
      });
    });

    group('typical usage patterns', () {
      test('should work with REST API parameters', () {
        final params = Parameters();

        // Simulating: GET /users/:userId/posts/:postId
        params.load({'userId': '42', 'postId': '789'});

        expect(params.get('userId'), equals('42'));
        expect(params.get('postId'), equals('789'));
      });

      test('should work with slug-based routing', () {
        final params = Parameters();

        // Simulating: GET /blog/:year/:month/:slug
        params.load({
          'year': '2025',
          'month': '11',
          'slug': 'my-blog-post',
        });

        expect(params.get('year'), equals('2025'));
        expect(params.get('month'), equals('11'));
        expect(params.get('slug'), equals('my-blog-post'));
      });

      test('should work with single parameter', () {
        final params = Parameters();

        // Simulating: GET /users/:id
        params.load({'id': '123'});

        expect(params.get('id'), equals('123'));
      });
    });
  });
}
