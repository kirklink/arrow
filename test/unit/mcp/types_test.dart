import 'package:test/test.dart';
import 'package:arrow/mcp.dart';

void main() {
  group('McpToolDefinition', () {
    test('constructs with required fields', () {
      const tool = McpToolDefinition(
        name: 'getUser',
        description: 'Get a user',
        inputSchema: {'type': 'object', 'properties': {}},
      );
      expect(tool.name, equals('getUser'));
      expect(tool.description, equals('Get a user'));
      expect(tool.method, isNull);
      expect(tool.path, isNull);
    });

    test('includes optional method and path', () {
      const tool = McpToolDefinition(
        name: 'getUser',
        description: 'Get a user',
        inputSchema: {},
        method: 'GET',
        path: '/users/{id}',
      );
      expect(tool.method, equals('GET'));
      expect(tool.path, equals('/users/{id}'));
    });

    test('toJson produces MCP-compatible format', () {
      const tool = McpToolDefinition(
        name: 'createUser',
        description: 'Create a user',
        inputSchema: {
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'description': 'User name'},
          },
        },
        method: 'POST',
        path: '/users',
      );
      final json = tool.toJson();
      expect(json['name'], equals('createUser'));
      expect(json['description'], equals('Create a user'));
      expect(json['inputSchema'], isA<Map>());
      // method and path are not in the MCP JSON output
      expect(json.containsKey('method'), isFalse);
      expect(json.containsKey('path'), isFalse);
    });
  });

  group('McpRequest', () {
    test('constructs with tool name', () {
      const req = McpRequest(toolName: 'getUser');
      expect(req.toolName, equals('getUser'));
      expect(req.arguments, isEmpty);
    });

    test('accepts arguments', () {
      const req = McpRequest(
        toolName: 'getUser',
        arguments: {'id': '123'},
      );
      expect(req.arguments, equals({'id': '123'}));
    });
  });

  group('McpToolResult', () {
    test('text factory creates text content', () {
      final result = McpToolResult.text('hello');
      expect(result.content, hasLength(1));
      expect(result.content.first, isA<McpTextContent>());
      expect((result.content.first as McpTextContent).text, equals('hello'));
      expect(result.isError, isFalse);
    });

    test('text factory with isError flag', () {
      final result = McpToolResult.text('fail', isError: true);
      expect(result.isError, isTrue);
    });

    test('toJson produces MCP-compatible format', () {
      final result = McpToolResult.text('data');
      final json = result.toJson();
      expect(json['content'], isA<List>());
      final content = (json['content'] as List).first as Map;
      expect(content['type'], equals('text'));
      expect(content['text'], equals('data'));
      expect(json.containsKey('isError'), isFalse);
    });

    test('toJson includes isError when true', () {
      final result = McpToolResult.text('error', isError: true);
      final json = result.toJson();
      expect(json['isError'], isTrue);
    });
  });

  group('McpTextContent', () {
    test('toJson produces correct format', () {
      const content = McpTextContent('hello');
      expect(content.toJson(), equals({'type': 'text', 'text': 'hello'}));
    });
  });
}
