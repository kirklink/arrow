import 'package:test/test.dart';
import 'package:arrow/mcp.dart';

void main() {
  group('McpServer', () {
    test('constructs with name and description', () {
      const server = McpServer('my-api', description: 'My API');
      expect(server.name, equals('my-api'));
      expect(server.description, equals('My API'));
      expect(server.version, equals('1.0.0'));
    });

    test('description defaults to null', () {
      const server = McpServer('my-api');
      expect(server.description, isNull);
    });

    test('version can be overridden', () {
      const server = McpServer('my-api', version: '2.0.0');
      expect(server.version, equals('2.0.0'));
    });
  });

  group('McpTool', () {
    test('constructs with required fields', () {
      const tool = McpTool(
        description: 'Get users',
        method: 'GET',
        path: '/users',
      );
      expect(tool.description, equals('Get users'));
      expect(tool.method, equals('GET'));
      expect(tool.path, equals('/users'));
      expect(tool.parameters, isEmpty);
    });

    test('accepts parameters map', () {
      const tool = McpTool(
        description: 'Get user',
        method: 'GET',
        path: '/users/{id}',
        parameters: {'id': 'The user ID'},
      );
      expect(tool.parameters, equals({'id': 'The user ID'}));
    });
  });
}
