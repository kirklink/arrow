import 'package:test/test.dart';
import 'package:arrow/src/request.dart';
import '../test_helpers.dart';

void main() {
  group('Request query parameter helpers', () {
    tearDownAll(() async {
      await cleanupAllMockRequests();
    });

    group('queryParam()', () {
      test('should return value for existing parameter', () async {
        final httpReq = await createMockGetRequest(path: '/test?name=Alice');
        final request = Request(httpReq);

        expect(request.queryParam('name'), equals('Alice'));

        await cleanupMockRequest(httpReq);
      });

      test('should return null for missing parameter', () async {
        final httpReq = await createMockGetRequest(path: '/test?name=Alice');
        final request = Request(httpReq);

        expect(request.queryParam('missing'), isNull);

        await cleanupMockRequest(httpReq);
      });

      test('should return defaultValue for missing parameter', () async {
        final httpReq = await createMockGetRequest(path: '/test');
        final request = Request(httpReq);

        expect(
          request.queryParam('page', defaultValue: '1'),
          equals('1'),
        );

        await cleanupMockRequest(httpReq);
      });

      test('should return actual value over defaultValue', () async {
        final httpReq = await createMockGetRequest(path: '/test?page=5');
        final request = Request(httpReq);

        expect(
          request.queryParam('page', defaultValue: '1'),
          equals('5'),
        );

        await cleanupMockRequest(httpReq);
      });

      test('should handle multiple parameters', () async {
        final httpReq = await createMockGetRequest(
          path: '/test?page=2&sort=name&order=asc',
        );
        final request = Request(httpReq);

        expect(request.queryParam('page'), equals('2'));
        expect(request.queryParam('sort'), equals('name'));
        expect(request.queryParam('order'), equals('asc'));

        await cleanupMockRequest(httpReq);
      });

      test('should handle empty value', () async {
        final httpReq = await createMockGetRequest(path: '/test?key=');
        final request = Request(httpReq);

        expect(request.queryParam('key'), equals(''));

        await cleanupMockRequest(httpReq);
      });
    });

    group('queryParams()', () {
      test('should return list for repeated parameters', () async {
        final httpReq = await createMockGetRequest(
          path: '/test?tag=dart&tag=flutter&tag=server',
        );
        final request = Request(httpReq);

        final tags = request.queryParams('tag');

        expect(tags, equals(['dart', 'flutter', 'server']));

        await cleanupMockRequest(httpReq);
      });

      test('should return single-element list for single param', () async {
        final httpReq = await createMockGetRequest(path: '/test?tag=dart');
        final request = Request(httpReq);

        expect(request.queryParams('tag'), equals(['dart']));

        await cleanupMockRequest(httpReq);
      });

      test('should return empty list for missing parameter', () async {
        final httpReq = await createMockGetRequest(path: '/test');
        final request = Request(httpReq);

        expect(request.queryParams('tags'), isEmpty);

        await cleanupMockRequest(httpReq);
      });
    });

    group('queryInt()', () {
      test('should parse integer value', () async {
        final httpReq = await createMockGetRequest(path: '/test?page=3');
        final request = Request(httpReq);

        expect(request.queryInt('page'), equals(3));

        await cleanupMockRequest(httpReq);
      });

      test('should return null for missing parameter', () async {
        final httpReq = await createMockGetRequest(path: '/test');
        final request = Request(httpReq);

        expect(request.queryInt('page'), isNull);

        await cleanupMockRequest(httpReq);
      });

      test('should return defaultValue for missing parameter', () async {
        final httpReq = await createMockGetRequest(path: '/test');
        final request = Request(httpReq);

        expect(request.queryInt('page', defaultValue: 1), equals(1));

        await cleanupMockRequest(httpReq);
      });

      test('should return defaultValue for non-integer value', () async {
        final httpReq = await createMockGetRequest(path: '/test?page=abc');
        final request = Request(httpReq);

        expect(request.queryInt('page', defaultValue: 1), equals(1));

        await cleanupMockRequest(httpReq);
      });

      test('should return null for non-integer without default', () async {
        final httpReq = await createMockGetRequest(path: '/test?page=abc');
        final request = Request(httpReq);

        expect(request.queryInt('page'), isNull);

        await cleanupMockRequest(httpReq);
      });

      test('should parse negative integers', () async {
        final httpReq = await createMockGetRequest(path: '/test?offset=-5');
        final request = Request(httpReq);

        expect(request.queryInt('offset'), equals(-5));

        await cleanupMockRequest(httpReq);
      });

      test('should parse zero', () async {
        final httpReq = await createMockGetRequest(path: '/test?page=0');
        final request = Request(httpReq);

        expect(request.queryInt('page'), equals(0));

        await cleanupMockRequest(httpReq);
      });
    });

    group('queryBool()', () {
      test('should parse "true"', () async {
        final httpReq = await createMockGetRequest(path: '/test?active=true');
        final request = Request(httpReq);

        expect(request.queryBool('active'), isTrue);

        await cleanupMockRequest(httpReq);
      });

      test('should parse "false"', () async {
        final httpReq = await createMockGetRequest(path: '/test?active=false');
        final request = Request(httpReq);

        expect(request.queryBool('active'), isFalse);

        await cleanupMockRequest(httpReq);
      });

      test('should parse "1" as true', () async {
        final httpReq = await createMockGetRequest(path: '/test?verbose=1');
        final request = Request(httpReq);

        expect(request.queryBool('verbose'), isTrue);

        await cleanupMockRequest(httpReq);
      });

      test('should parse "0" as false', () async {
        final httpReq = await createMockGetRequest(path: '/test?verbose=0');
        final request = Request(httpReq);

        expect(request.queryBool('verbose'), isFalse);

        await cleanupMockRequest(httpReq);
      });

      test('should parse "yes" as true', () async {
        final httpReq = await createMockGetRequest(path: '/test?debug=yes');
        final request = Request(httpReq);

        expect(request.queryBool('debug'), isTrue);

        await cleanupMockRequest(httpReq);
      });

      test('should parse "no" as false', () async {
        final httpReq = await createMockGetRequest(path: '/test?debug=no');
        final request = Request(httpReq);

        expect(request.queryBool('debug'), isFalse);

        await cleanupMockRequest(httpReq);
      });

      test('should be case-insensitive', () async {
        final httpReq = await createMockGetRequest(path: '/test?a=TRUE&b=False&c=YES');
        final request = Request(httpReq);

        expect(request.queryBool('a'), isTrue);
        expect(request.queryBool('b'), isFalse);
        expect(request.queryBool('c'), isTrue);

        await cleanupMockRequest(httpReq);
      });

      test('should return null for missing parameter', () async {
        final httpReq = await createMockGetRequest(path: '/test');
        final request = Request(httpReq);

        expect(request.queryBool('missing'), isNull);

        await cleanupMockRequest(httpReq);
      });

      test('should return defaultValue for missing parameter', () async {
        final httpReq = await createMockGetRequest(path: '/test');
        final request = Request(httpReq);

        expect(request.queryBool('active', defaultValue: false), isFalse);

        await cleanupMockRequest(httpReq);
      });

      test('should return defaultValue for unrecognized value', () async {
        final httpReq = await createMockGetRequest(path: '/test?flag=maybe');
        final request = Request(httpReq);

        expect(request.queryBool('flag', defaultValue: false), isFalse);

        await cleanupMockRequest(httpReq);
      });
    });

    group('query helpers with no query string', () {
      test('all helpers should handle empty query string', () async {
        final httpReq = await createMockGetRequest(path: '/test');
        final request = Request(httpReq);

        expect(request.queryParam('any'), isNull);
        expect(request.queryParams('any'), isEmpty);
        expect(request.queryInt('any'), isNull);
        expect(request.queryBool('any'), isNull);

        await cleanupMockRequest(httpReq);
      });
    });
  });
}
