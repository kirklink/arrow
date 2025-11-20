import 'package:test/test.dart';
import 'package:arrow/src/context.dart';

void main() {
  group('Context', () {
    late Context context;

    setUp(() {
      context = Context();
    });

    group('setOrReplace', () {
      test('should set a new value', () {
        final result = context.setOrReplace('key1', 'value1');
        expect(result, equals('value1'));
        expect(context.tryGet<String>('key1'), equals('value1'));
      });

      test('should replace an existing value', () {
        context.setOrReplace('key1', 'value1');
        final result = context.setOrReplace('key1', 'value2');
        expect(result, equals('value2'));
        expect(context.tryGet<String>('key1'), equals('value2'));
      });

      test('should handle different types', () {
        context.setOrReplace('string', 'hello');
        context.setOrReplace('int', 42);
        context.setOrReplace('bool', true);
        context.setOrReplace('list', [1, 2, 3]);

        expect(context.tryGet<String>('string'), equals('hello'));
        expect(context.tryGet<int>('int'), equals(42));
        expect(context.tryGet<bool>('bool'), equals(true));
        expect(context.tryGet<List>('list'), equals([1, 2, 3]));
      });
    });

    group('trySet', () {
      test('should set a new value and return it', () {
        final result = context.trySet('key1', 'value1');
        expect(result, equals('value1'));
        expect(context.tryGet<String>('key1'), equals('value1'));
      });

      test('should return null if key already exists', () {
        context.trySet('key1', 'value1');
        final result = context.trySet('key1', 'value2');
        expect(result, isNull);
        expect(context.tryGet<String>('key1'), equals('value1'));
      });
    });

    group('tryGet', () {
      test('should return null for non-existent key', () {
        expect(context.tryGet<String>('nonexistent'), isNull);
      });

      test('should return value for existing key', () {
        context.setOrReplace('key1', 'value1');
        expect(context.tryGet<String>('key1'), equals('value1'));
      });
    });

    group('getOrSet', () {
      test('should set and return value if key does not exist', () {
        final result = context.getOrSet('key1', 'value1');
        expect(result, equals('value1'));
        expect(context.tryGet<String>('key1'), equals('value1'));
      });

      test('should return existing value if key exists', () {
        context.setOrReplace('key1', 'original');
        final result = context.getOrSet('key1', 'new');
        expect(result, equals('original'));
        expect(context.tryGet<String>('key1'), equals('original'));
      });
    });

    group('has', () {
      test('should return false for non-existent key', () {
        expect(context.has('nonexistent'), isFalse);
      });

      test('should return true for existing key', () {
        context.setOrReplace('key1', 'value1');
        expect(context.has('key1'), isTrue);
      });
    });

    group('tryDelete', () {
      test('should return null for non-existent key', () {
        final result = context.tryDelete<String>('nonexistent');
        expect(result, isNull);
      });

      test('should return and remove existing value', () {
        context.setOrReplace('key1', 'value1');
        final result = context.tryDelete<String>('key1');
        expect(result, equals('value1'));
        expect(context.has('key1'), isFalse);
      });
    });

    group('makeKey', () {
      test('should generate unique keys', () {
        final key1 = Context.makeKey();
        final key2 = Context.makeKey();
        final key3 = Context.makeKey();

        expect(key1, isNotEmpty);
        expect(key2, isNotEmpty);
        expect(key3, isNotEmpty);
        expect(key1, isNot(equals(key2)));
        expect(key2, isNot(equals(key3)));
        expect(key1, isNot(equals(key3)));
      });

      test('should generate valid UUID v4 format', () {
        final key = Context.makeKey();
        // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          caseSensitive: false,
        );
        expect(key, matches(uuidRegex));
      });
    });

    group('concurrent modifications', () {
      test('should handle multiple keys being set', () {
        context.setOrReplace('key1', 'value1');
        context.setOrReplace('key2', 'value2');
        context.setOrReplace('key3', 'value3');

        expect(context.tryGet<String>('key1'), equals('value1'));
        expect(context.tryGet<String>('key2'), equals('value2'));
        expect(context.tryGet<String>('key3'), equals('value3'));
      });

      test('should preserve independent keys when one is deleted', () {
        context.setOrReplace('key1', 'value1');
        context.setOrReplace('key2', 'value2');
        context.tryDelete('key1');

        expect(context.has('key1'), isFalse);
        expect(context.tryGet<String>('key2'), equals('value2'));
      });
    });
  });
}
