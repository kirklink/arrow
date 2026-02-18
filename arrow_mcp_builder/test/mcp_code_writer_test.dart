import 'package:test/test.dart';
import 'package:arrow_mcp_builder/src/mcp_code_writer.dart';

void main() {
  group('McpCodeWriter', () {
    test('generates header with server info and http imports', () {
      final writer = McpCodeWriter(
        serverName: 'test-api',
        serverDescription: 'Test API',
        serverVersion: '1.0.0',
      );
      final output = writer.build();
      expect(output, contains('GENERATED CODE - DO NOT MODIFY BY HAND'));
      expect(output, contains('test-api'));
      expect(output, contains('Test API'));
      expect(output, contains("import 'dart:convert' show json;"));
      expect(output, contains("import 'package:http/http.dart' as http;"));
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

    test('dispatcher extends McpDispatcher with baseUrl and http.Client', () {
      final writer = McpCodeWriter(
        serverName: 'my-api',
        serverVersion: '1.0.0',
      );
      final output = writer.build();
      expect(output, contains('extends McpDispatcher'));
      expect(output, contains('final String baseUrl;'));
      expect(output, contains('final http.Client _client;'));
      expect(output, contains('MyApiMcpDispatcher(this.baseUrl'));
      expect(output, contains('{http.Client? client}'));
    });

    test('GET handler generates http.get call', () {
      final writer = McpCodeWriter(
        serverName: 'my-api',
        serverVersion: '1.0.0',
      );
      writer.addTool(
        fieldName: 'getUsers',
        description: 'Get users',
        method: 'GET',
        path: '/users',
        pathParams: [],
        parameters: {},
      );
      final output = writer.build();
      expect(output, contains('_client.get(url)'));
      expect(output, contains('McpToolResult.text(response.body)'));
      expect(output, contains('response.statusCode >= 200'));
    });

    test('POST handler generates http.post with JSON body', () {
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
        parameters: {'name': 'User name'},
      );
      final output = writer.build();
      expect(output, contains('_client.post(url,'));
      expect(output, contains("'Content-Type': 'application/json'"));
      expect(output, contains('json.encode(body)'));
    });

    test('DELETE handler generates http.delete call', () {
      final writer = McpCodeWriter(
        serverName: 'my-api',
        serverVersion: '1.0.0',
      );
      writer.addTool(
        fieldName: 'deleteUser',
        description: 'Delete user',
        method: 'DELETE',
        path: '/users/{id}',
        pathParams: ['id'],
        parameters: {'id': 'User ID'},
      );
      final output = writer.build();
      expect(output, contains('_client.delete(url)'));
      expect(output, contains('Uri.encodeComponent'));
    });

    test('PUT handler generates http.put with JSON body excluding path params',
        () {
      final writer = McpCodeWriter(
        serverName: 'my-api',
        serverVersion: '1.0.0',
      );
      writer.addTool(
        fieldName: 'updateUser',
        description: 'Update user',
        method: 'PUT',
        path: '/users/{id}',
        pathParams: ['id'],
        parameters: {'id': 'User ID', 'name': 'Updated name'},
      );
      final output = writer.build();
      expect(output, contains('_client.put(url,'));
      expect(output, contains("'id'"));
      // Path params should be excluded from body
      expect(output, contains('.contains(entry.key)'));
    });

    test('error response includes status code', () {
      final writer = McpCodeWriter(
        serverName: 'my-api',
        serverVersion: '1.0.0',
      );
      writer.addTool(
        fieldName: 'getStuff',
        description: 'Get stuff',
        method: 'GET',
        path: '/stuff',
        pathParams: [],
        parameters: {},
      );
      final output = writer.build();
      expect(output, contains('response.statusCode'));
      expect(output, contains('isError: true'));
    });
  });
}
