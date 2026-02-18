import 'package:test/test.dart';
import 'package:arrow_mcp_builder/src/mcp_code_writer.dart';

void main() {
  group('McpCodeWriter', () {
    test('generates header with server info', () {
      final writer = McpCodeWriter(
        serverName: 'test-api',
        serverDescription: 'Test API',
        serverVersion: '1.0.0',
      );
      final output = writer.build();
      expect(output, contains('GENERATED CODE - DO NOT MODIFY BY HAND'));
      expect(output, contains('test-api'));
      expect(output, contains('Test API'));
      expect(output, contains("import 'package:arrow/mcp.dart'"));
    });

    test('generates empty tool list for server with no tools', () {
      final writer = McpCodeWriter(
        serverName: 'empty-api',
        serverVersion: '1.0.0',
      );
      final output = writer.build();
      expect(output, contains('const emptyApiTools = <McpToolDefinition>['));
      expect(output, contains('];'));
    });

    test('generates single tool definition', () {
      final writer = McpCodeWriter(
        serverName: 'my-api',
        serverVersion: '1.0.0',
      );
      writer.addTool(
        fieldName: 'getUsers',
        description: 'Get all users',
        method: 'GET',
        path: '/users',
        pathParams: [],
        parameters: {},
      );
      final output = writer.build();
      expect(output, contains("name: 'getUsers'"));
      expect(output, contains("description: 'Get all users'"));
      expect(output, contains("method: 'GET'"));
      expect(output, contains("path: '/users'"));
    });

    test('path params are extracted and added to required', () {
      final writer = McpCodeWriter(
        serverName: 'my-api',
        serverVersion: '1.0.0',
      );
      writer.addTool(
        fieldName: 'getUser',
        description: 'Get user',
        method: 'GET',
        path: '/users/{id}',
        pathParams: ['id'],
        parameters: {'id': 'The user ID'},
      );
      final output = writer.build();
      expect(output, contains("'required': <String>['id']"));
      expect(output, contains("'description': 'The user ID'"));
    });

    test('parameters map is included in inputSchema properties', () {
      final writer = McpCodeWriter(
        serverName: 'my-api',
        serverVersion: '1.0.0',
      );
      writer.addTool(
        fieldName: 'createUser',
        description: 'Create user',
        method: 'POST',
        path: '/users',
        pathParams: [],
        parameters: {'name': 'User name', 'email': 'User email'},
      );
      final output = writer.build();
      expect(output, contains("'name': {"));
      expect(output, contains("'description': 'User name'"));
      expect(output, contains("'email': {"));
      expect(output, contains("'description': 'User email'"));
    });

    test('server name is converted to PascalCase for class name', () {
      final writer = McpCodeWriter(
        serverName: 'user-api',
        serverVersion: '1.0.0',
      );
      final output = writer.build();
      expect(output, contains('class UserApiMcpDispatcher'));
    });

    test('multiple tools produce correct tool list and switch cases', () {
      final writer = McpCodeWriter(
        serverName: 'multi-api',
        serverVersion: '1.0.0',
      );
      writer.addTool(
        fieldName: 'toolA',
        description: 'Tool A',
        method: 'GET',
        path: '/a',
        pathParams: [],
        parameters: {},
      );
      writer.addTool(
        fieldName: 'toolB',
        description: 'Tool B',
        method: 'POST',
        path: '/b',
        pathParams: [],
        parameters: {},
      );
      final output = writer.build();
      expect(output, contains('_toolATool'));
      expect(output, contains('_toolBTool'));
      expect(output, contains('const multiApiTools = <McpToolDefinition>['));
      expect(output, contains("case 'toolA':"));
      expect(output, contains("case 'toolB':"));
    });

    test('escapes single quotes in descriptions', () {
      final writer = McpCodeWriter(
        serverName: 'my-api',
        serverVersion: '1.0.0',
      );
      writer.addTool(
        fieldName: 'test',
        description: "It's a test",
        method: 'GET',
        path: '/test',
        pathParams: [],
        parameters: {},
      );
      final output = writer.build();
      expect(output, contains("It\\'s a test"));
    });

    test('dispatcher extends McpDispatcher', () {
      final writer = McpCodeWriter(
        serverName: 'my-api',
        serverVersion: '1.0.0',
      );
      final output = writer.build();
      expect(output, contains('extends McpDispatcher'));
    });
  });
}
