/// Builds MCP server code from route information

class McpTool {
  final String name;
  final String method;
  final String path;
  final String description;
  final Map<String, String>? parameters;

  McpTool({
    required this.name,
    required this.method,
    required this.path,
    required this.description,
    this.parameters,
  });

  /// Extract path parameters from route path
  List<String> get pathParams {
    final regex = RegExp(r'\{([^}]+)\}');
    final matches = regex.allMatches(path);
    return matches.map((m) => m.group(1)!).toList();
  }

  /// Build the URL with path parameters replaced
  String buildUrl(String baseUrl) {
    var url = path;
    for (final param in pathParams) {
      url = url.replaceAll('{$param}', '\${args[\'$param\']}');
    }
    return '$baseUrl$url';
  }
}

/// Builds MCP server source code
class McpServerBuilder {
  String _serverName = 'api_server';
  String? _serverDescription;
  String _baseUrl = 'http://localhost:8080';
  final List<McpTool> _tools = [];

  void setServerInfo(String name, String? description) {
    _serverName = name;
    _serverDescription = description;
  }

  void setBaseUrl(String url) {
    // Add protocol if missing
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    _baseUrl = url;
  }

  void addTool({
    required String name,
    required String method,
    required String path,
    required String description,
    Map<String, String>? parameters,
  }) {
    _tools.add(McpTool(
      name: name,
      method: method,
      path: path,
      description: description,
      parameters: parameters,
    ));
  }

  /// Build the complete MCP server code
  String build() {
    final buffer = StringBuffer();

    // Header
    _writeHeader(buffer);

    // MCP Server class
    _writeServerClass(buffer);

    // Main function
    _writeMain(buffer);

    return buffer.toString();
  }

  void _writeHeader(StringBuffer buffer) {
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// MCP Server generated from Arrow routes');
    buffer.writeln('// Server: $_serverName');
    if (_serverDescription != null) {
      buffer.writeln('// Description: $_serverDescription');
    }
    buffer.writeln();
    buffer.writeln("import 'dart:async';");
    buffer.writeln("import 'dart:convert';");
    buffer.writeln("import 'package:mcp_server/mcp_server.dart';");
    buffer.writeln("import 'package:http/http.dart' as http;");
    buffer.writeln();
  }

  void _writeServerClass(StringBuffer buffer) {
    final className = _toPascalCase(_serverName);

    buffer.writeln('class ${className}Server extends McpServer {');
    buffer.writeln('  final String baseUrl = \'$_baseUrl\';');
    buffer.writeln('  final http.Client client = http.Client();');
    buffer.writeln();

    // Constructor
    buffer.writeln('  ${className}Server() : super(');
    buffer.writeln('    name: \'$_serverName\',');
    buffer.writeln('    version: \'1.0.0\',');
    if (_serverDescription != null) {
      buffer.writeln('    description: \'$_serverDescription\',');
    }
    buffer.writeln('  );');
    buffer.writeln();

    // Tools list
    _writeToolsList(buffer);
    buffer.writeln();

    // Call tool method
    _writeCallTool(buffer);
    buffer.writeln();

    // Helper methods for each tool
    _writeToolMethods(buffer);

    buffer.writeln('}');
    buffer.writeln();
  }

  void _writeToolsList(StringBuffer buffer) {
    buffer.writeln('  @override');
    buffer.writeln('  List<Tool> get tools => [');

    for (final tool in _tools) {
      buffer.writeln('    Tool(');
      buffer.writeln('      name: \'${tool.name}\',');
      buffer.writeln('      description: \'${tool.description}\',');
      buffer.writeln('      inputSchema: {');
      buffer.writeln('        \'type\': \'object\',');

      if (tool.pathParams.isNotEmpty || tool.parameters != null) {
        buffer.writeln('        \'properties\': {');

        // Path parameters
        for (final param in tool.pathParams) {
          buffer.writeln('          \'$param\': {');
          buffer.writeln('            \'type\': \'string\',');
          buffer.writeln('            \'description\': \'${_humanize(param)}\',');
          buffer.writeln('          },');
        }

        // Additional parameters from annotation
        if (tool.parameters != null) {
          for (final entry in tool.parameters!.entries) {
            buffer.writeln('          \'${entry.key}\': {');
            buffer.writeln('            \'type\': \'string\',');
            buffer.writeln('            \'description\': \'${entry.value}\',');
            buffer.writeln('          },');
          }
        }

        buffer.writeln('        },');

        // Required parameters
        if (tool.pathParams.isNotEmpty) {
          buffer.writeln('        \'required\': [${tool.pathParams.map((p) => '\'$p\'').join(', ')}],');
        }
      }

      buffer.writeln('      },');
      buffer.writeln('    ),');
    }

    buffer.writeln('  ];');
  }

  void _writeCallTool(StringBuffer buffer) {
    buffer.writeln('  @override');
    buffer.writeln('  Future<ToolResult> callTool(String name, Map<String, dynamic> args) async {');
    buffer.writeln('    try {');
    buffer.writeln('      switch (name) {');

    for (final tool in _tools) {
      buffer.writeln('        case \'${tool.name}\':');
      buffer.writeln('          return await _${tool.name}(args);');
    }

    buffer.writeln('        default:');
    buffer.writeln('          throw McpError(');
    buffer.writeln('            code: ErrorCode.methodNotFound,');
    buffer.writeln('            message: \'Unknown tool: \$name\',');
    buffer.writeln('          );');
    buffer.writeln('      }');
    buffer.writeln('    } catch (e, stack) {');
    buffer.writeln('      return ToolResult(');
    buffer.writeln('        content: [');
    buffer.writeln('          TextContent(\'Error calling \$name: \$e\'),');
    buffer.writeln('        ],');
    buffer.writeln('        isError: true,');
    buffer.writeln('      );');
    buffer.writeln('    }');
    buffer.writeln('  }');
  }

  void _writeToolMethods(StringBuffer buffer) {
    for (final tool in _tools) {
      buffer.writeln('  Future<ToolResult> _${tool.name}(Map<String, dynamic> args) async {');
      buffer.writeln('    final url = Uri.parse(\'${tool.buildUrl(_baseUrl)}\');');
      buffer.writeln();

      // Make HTTP request
      final methodLower = tool.method.toLowerCase();
      if (methodLower == 'get' || methodLower == 'delete') {
        buffer.writeln('    final response = await client.$methodLower(url);');
      } else {
        // POST, PUT - include body
        buffer.writeln('    final body = jsonEncode(args);');
        buffer.writeln('    final response = await client.$methodLower(');
        buffer.writeln('      url,');
        buffer.writeln('      headers: {\'Content-Type\': \'application/json\'},');
        buffer.writeln('      body: body,');
        buffer.writeln('    );');
      }

      buffer.writeln();
      buffer.writeln('    if (response.statusCode >= 200 && response.statusCode < 300) {');
      buffer.writeln('      return ToolResult(');
      buffer.writeln('        content: [TextContent(response.body)],');
      buffer.writeln('      );');
      buffer.writeln('    } else {');
      buffer.writeln('      return ToolResult(');
      buffer.writeln('        content: [TextContent(\'HTTP \${response.statusCode}: \${response.body}\')],');
      buffer.writeln('        isError: true,');
      buffer.writeln('      );');
      buffer.writeln('    }');
      buffer.writeln('  }');
      buffer.writeln();
    }
  }

  void _writeMain(StringBuffer buffer) {
    final className = _toPascalCase(_serverName);

    buffer.writeln('void main() async {');
    buffer.writeln('  final server = ${className}Server();');
    buffer.writeln('  await server.run();');
    buffer.writeln('}');
  }

  String _toPascalCase(String text) {
    return text.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join('');
  }

  String _humanize(String camelCase) {
    // Convert camelCase to "Human readable"
    final words = camelCase.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim();
    return words[0].toUpperCase() + words.substring(1);
  }
}
