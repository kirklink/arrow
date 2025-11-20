import 'package:test/test.dart';
import 'package:arrow/src/request.dart';
import '../test_helpers.dart';

void main() {
  group('Request', () {
    tearDownAll(() async {
      // Clean up any remaining mock servers
      await cleanupAllMockRequests();
    });

    test('should be created from HttpRequest', () async {
      final mockHttpRequest = await createMockHttpRequest();
      final request = Request(mockHttpRequest);

      expect(request.method, equals('GET'));
      expect(request.uri.path, equals('/test'));
      expect(request.isAlive, isTrue);

      await cleanupMockRequest(mockHttpRequest);
    });

    test('should have empty context initially', () async {
      final mockHttpRequest = await createMockHttpRequest();
      final request = Request(mockHttpRequest);

      expect(request.context.has('any-key'), isFalse);

      await cleanupMockRequest(mockHttpRequest);
    });

    test('should allow setting context values', () async {
      final mockHttpRequest = await createMockHttpRequest();
      final request = Request(mockHttpRequest);

      request.context.setOrReplace('user', 'Alice');
      request.context.setOrReplace('role', 'Admin');

      expect(request.context.tryGet<String>('user'), equals('Alice'));
      expect(request.context.tryGet<String>('role'), equals('Admin'));

      await cleanupMockRequest(mockHttpRequest);
    });

    test('should be cancellable', () async {
      final mockHttpRequest = await createMockHttpRequest();
      final request = Request(mockHttpRequest);

      expect(request.isAlive, isTrue);

      request.cancel();

      expect(request.isAlive, isFalse);

      await cleanupMockRequest(mockHttpRequest);
    });

    test('should have access to HTTP headers', () async {
      final mockHttpRequest = await createMockHttpRequest();
      final request = Request(mockHttpRequest);

      // Headers exist (even if empty)
      expect(request.headers, isNotNull);

      await cleanupMockRequest(mockHttpRequest);
    });

    test('should have messenger for tracking messages', () async {
      final mockHttpRequest = await createMockHttpRequest();
      final request = Request(mockHttpRequest);

      expect(request.messenger, isNotNull);

      request.messenger.addMessage('Test message');
      request.messenger.addError('Test error');

      expect(request.messenger.messages, contains('Test message'));
      expect(request.messenger.errors, contains('Test error'));

      await cleanupMockRequest(mockHttpRequest);
    });
  });
}
