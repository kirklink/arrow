import 'package:test/test.dart';
import 'package:arrow/src/internal_messenger.dart';

void main() {
  group('InternalMessenger', () {
    test('should start with empty messages and errors', () {
      final messenger = InternalMessenger();

      expect(messenger.messages, isEmpty);
      expect(messenger.errors, isEmpty);
    });

    group('addMessage()', () {
      test('should add single message', () {
        final messenger = InternalMessenger();

        messenger.addMessage('Test message');

        expect(messenger.messages, hasLength(1));
        expect(messenger.messages, contains('Test message'));
      });

      test('should add multiple messages', () {
        final messenger = InternalMessenger();

        messenger.addMessage('First message');
        messenger.addMessage('Second message');
        messenger.addMessage('Third message');

        expect(messenger.messages, hasLength(3));
        expect(messenger.messages[0], equals('First message'));
        expect(messenger.messages[1], equals('Second message'));
        expect(messenger.messages[2], equals('Third message'));
      });

      test('should preserve message order', () {
        final messenger = InternalMessenger();

        messenger.addMessage('A');
        messenger.addMessage('B');
        messenger.addMessage('C');

        expect(messenger.messages, equals(['A', 'B', 'C']));
      });

      test('should allow duplicate messages', () {
        final messenger = InternalMessenger();

        messenger.addMessage('Duplicate');
        messenger.addMessage('Duplicate');
        messenger.addMessage('Duplicate');

        expect(messenger.messages, hasLength(3));
        expect(messenger.messages, equals(['Duplicate', 'Duplicate', 'Duplicate']));
      });

      test('should handle empty string messages', () {
        final messenger = InternalMessenger();

        messenger.addMessage('');
        messenger.addMessage('Non-empty');
        messenger.addMessage('');

        expect(messenger.messages, hasLength(3));
        expect(messenger.messages[0], equals(''));
        expect(messenger.messages[1], equals('Non-empty'));
        expect(messenger.messages[2], equals(''));
      });

      test('should handle long messages', () {
        final messenger = InternalMessenger();

        final longMessage = 'This is a very long message ' * 100;
        messenger.addMessage(longMessage);

        expect(messenger.messages, hasLength(1));
        expect(messenger.messages[0], equals(longMessage));
      });

      test('should handle special characters', () {
        final messenger = InternalMessenger();

        messenger.addMessage('Message with\nnewlines');
        messenger.addMessage('Message with\ttabs');
        messenger.addMessage('Message with "quotes"');
        messenger.addMessage("Message with 'apostrophes'");

        expect(messenger.messages, hasLength(4));
        expect(messenger.messages[0], equals('Message with\nnewlines'));
        expect(messenger.messages[1], equals('Message with\ttabs'));
        expect(messenger.messages[2], equals('Message with "quotes"'));
        expect(messenger.messages[3], equals("Message with 'apostrophes'"));
      });
    });

    group('addError()', () {
      test('should add single error', () {
        final messenger = InternalMessenger();

        messenger.addError('Test error');

        expect(messenger.errors, hasLength(1));
        expect(messenger.errors, contains('Test error'));
      });

      test('should add multiple errors', () {
        final messenger = InternalMessenger();

        messenger.addError('First error');
        messenger.addError('Second error');
        messenger.addError('Third error');

        expect(messenger.errors, hasLength(3));
        expect(messenger.errors[0], equals('First error'));
        expect(messenger.errors[1], equals('Second error'));
        expect(messenger.errors[2], equals('Third error'));
      });

      test('should preserve error order', () {
        final messenger = InternalMessenger();

        messenger.addError('Error A');
        messenger.addError('Error B');
        messenger.addError('Error C');

        expect(messenger.errors, equals(['Error A', 'Error B', 'Error C']));
      });

      test('should allow duplicate errors', () {
        final messenger = InternalMessenger();

        messenger.addError('Same error');
        messenger.addError('Same error');

        expect(messenger.errors, hasLength(2));
        expect(messenger.errors, equals(['Same error', 'Same error']));
      });

      test('should handle empty string errors', () {
        final messenger = InternalMessenger();

        messenger.addError('');
        messenger.addError('Non-empty error');

        expect(messenger.errors, hasLength(2));
        expect(messenger.errors[0], equals(''));
        expect(messenger.errors[1], equals('Non-empty error'));
      });
    });

    group('messages and errors independence', () {
      test('should track messages and errors independently', () {
        final messenger = InternalMessenger();

        messenger.addMessage('Info message');
        messenger.addError('Error message');
        messenger.addMessage('Another info');
        messenger.addError('Another error');

        expect(messenger.messages, hasLength(2));
        expect(messenger.errors, hasLength(2));
        expect(messenger.messages, equals(['Info message', 'Another info']));
        expect(messenger.errors, equals(['Error message', 'Another error']));
      });

      test('should not mix messages and errors', () {
        final messenger = InternalMessenger();

        messenger.addMessage('This is a message');
        messenger.addError('This is an error');

        expect(messenger.messages, isNot(contains('This is an error')));
        expect(messenger.errors, isNot(contains('This is a message')));
      });

      test('should allow messages without errors', () {
        final messenger = InternalMessenger();

        messenger.addMessage('Message 1');
        messenger.addMessage('Message 2');

        expect(messenger.messages, hasLength(2));
        expect(messenger.errors, isEmpty);
      });

      test('should allow errors without messages', () {
        final messenger = InternalMessenger();

        messenger.addError('Error 1');
        messenger.addError('Error 2');

        expect(messenger.errors, hasLength(2));
        expect(messenger.messages, isEmpty);
      });
    });

    group('getters', () {
      test('messages getter should return list', () {
        final messenger = InternalMessenger();

        messenger.addMessage('Test');

        expect(messenger.messages, isA<List<String>>());
        expect(messenger.messages, isNotNull);
      });

      test('errors getter should return list', () {
        final messenger = InternalMessenger();

        messenger.addError('Test error');

        expect(messenger.errors, isA<List<String>>());
        expect(messenger.errors, isNotNull);
      });

      test('messages getter should return actual list', () {
        final messenger = InternalMessenger();

        messenger.addMessage('First');
        final list1 = messenger.messages;
        messenger.addMessage('Second');
        final list2 = messenger.messages;

        // Should return the same underlying list
        expect(identical(list1, list2), isTrue);
        expect(list2, hasLength(2));
      });
    });

    group('typical usage patterns', () {
      test('should track middleware processing messages', () {
        final messenger = InternalMessenger();

        messenger.addMessage('Middleware: Auth check started');
        messenger.addMessage('Middleware: User authenticated');
        messenger.addMessage('Middleware: CORS headers set');
        messenger.addMessage('Handler: Processing request');

        expect(messenger.messages, hasLength(4));
        expect(messenger.errors, isEmpty);
      });

      test('should track validation errors', () {
        final messenger = InternalMessenger();

        messenger.addError('Validation: Email is required');
        messenger.addError('Validation: Password too short');
        messenger.addError('Validation: Age must be positive');

        expect(messenger.errors, hasLength(3));
        expect(messenger.messages, isEmpty);
      });

      test('should track both success and failure', () {
        final messenger = InternalMessenger();

        messenger.addMessage('Request received');
        messenger.addMessage('Auth check passed');
        messenger.addError('Database connection failed');
        messenger.addError('Retry attempt 1 failed');
        messenger.addMessage('Retry attempt 2 succeeded');

        expect(messenger.messages, hasLength(3));
        expect(messenger.errors, hasLength(2));
      });

      test('should work with request lifecycle tracking', () {
        final messenger = InternalMessenger();

        // Middleware phase
        messenger.addMessage('Middleware: Logger started');
        messenger.addMessage('Middleware: Auth completed');

        // Handler phase
        messenger.addMessage('Handler: Processing user request');

        // Potential errors
        messenger.addError('Handler: User not found');

        // Response phase
        messenger.addMessage('Response: Sending 404');

        expect(messenger.messages, hasLength(4));
        expect(messenger.errors, hasLength(1));
      });
    });
  });
}
