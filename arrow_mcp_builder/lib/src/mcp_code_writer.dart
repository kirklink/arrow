import 'package:recase/recase.dart';

class _ToolInfo {
  final String fieldName;
  final String description;
  final String method;
  final String path;
  final List<String> pathParams;
  final Map<String, String> parameters;

  _ToolInfo({
    required this.fieldName,
    required this.description,
    required this.method,
    required this.path,
    required this.pathParams,
    required this.parameters,
  });
}

class McpCodeWriter {
  final String serverName;
  final String? serverDescription;
  final String serverVersion;
  final List<_ToolInfo> _tools = [];

  McpCodeWriter({
    required this.serverName,
    this.serverDescription,
    required this.serverVersion,
  });

  void addTool({
    required String fieldName,
    required String description,
    required String method,
    required String path,
    required List<String> pathParams,
    required Map<String, String> parameters,
  }) {
    _tools.add(_ToolInfo(
      fieldName: fieldName,
      description: description,
      method: method,
      path: path,
      pathParams: pathParams,
      parameters: parameters,
    ));
  }

  String build() {
    final buf = StringBuffer();
    final classPrefix = ReCase(serverName).pascalCase;

    _writeHeader(buf);
    _writeToolDefinitions(buf);
    _writeToolList(buf, classPrefix);
    _writeDispatcher(buf, classPrefix);

    return buf.toString();
  }

  void _writeHeader(StringBuffer buf) {
    buf.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buf.writeln(
        '// MCP server definitions generated for server: $serverName');
    if (serverDescription != null) {
      buf.writeln('// Description: $serverDescription');
    }
    buf.writeln();
    buf.writeln("import 'dart:convert' show json;");
    buf.writeln();
    buf.writeln("import 'package:http/http.dart' as http;");
    buf.writeln();
    buf.writeln("import 'package:arrow/mcp.dart';");
    buf.writeln();
  }

  void _writeToolDefinitions(StringBuffer buf) {
    for (final tool in _tools) {
      buf.writeln('const _${tool.fieldName}Tool = McpToolDefinition(');
      buf.writeln("  name: '${tool.fieldName}',");
      buf.writeln("  description: '${_escape(tool.description)}',");
      buf.writeln("  method: '${tool.method}',");
      buf.writeln("  path: '${tool.path}',");
      buf.writeln('  inputSchema: {');
      buf.writeln("    'type': 'object',");
      _writeProperties(buf, tool);
      buf.writeln('  },');
      buf.writeln(');');
      buf.writeln();
    }
  }

  void _writeProperties(StringBuffer buf, _ToolInfo tool) {
    // Build properties from the parameters map.
    final allParams = <String, String>{};
    // Path params get descriptions from the parameters map if available.
    for (final p in tool.pathParams) {
      allParams[p] = tool.parameters[p] ?? p;
    }
    // Add non-path parameters (body/query params).
    for (final entry in tool.parameters.entries) {
      if (!tool.pathParams.contains(entry.key)) {
        allParams[entry.key] = entry.value;
      }
    }

    if (allParams.isEmpty) {
      buf.writeln("    'properties': <String, Object>{},");
    } else {
      buf.writeln("    'properties': {");
      for (final entry in allParams.entries) {
        buf.writeln("      '${entry.key}': {");
        buf.writeln("        'type': 'string',");
        buf.writeln(
            "        'description': '${_escape(entry.value)}',");
        buf.writeln('      },');
      }
      buf.writeln('    },');
    }

    // Path params are always required.
    if (tool.pathParams.isNotEmpty) {
      final required =
          tool.pathParams.map((p) => "'$p'").join(', ');
      buf.writeln("    'required': <String>[$required],");
    }
  }

  void _writeToolList(StringBuffer buf, String classPrefix) {
    final listName = '${ReCase(serverName).camelCase}Tools';
    buf.writeln('/// All MCP tool definitions for the $serverName server.');
    buf.writeln('const $listName = <McpToolDefinition>[');
    for (final tool in _tools) {
      buf.writeln('  _${tool.fieldName}Tool,');
    }
    buf.writeln('];');
    buf.writeln();
  }

  void _writeDispatcher(StringBuffer buf, String classPrefix) {
    final className = '${classPrefix}McpDispatcher';
    final listName = '${ReCase(serverName).camelCase}Tools';

    buf.writeln('/// Generated HTTP proxy dispatcher for $serverName MCP tools.');
    buf.writeln('///');
    buf.writeln('/// Each tool call is proxied as an HTTP request to the Arrow server');
    buf.writeln('/// at [baseUrl]. Pass an optional [http.Client] for testing or');
    buf.writeln('/// connection reuse.');
    buf.writeln('class $className extends McpDispatcher {');
    buf.writeln('  final String baseUrl;');
    buf.writeln('  final http.Client _client;');
    buf.writeln();
    buf.writeln('  $className(this.baseUrl, {http.Client? client})');
    buf.writeln('      : _client = client ?? http.Client();');
    buf.writeln();
    buf.writeln('  @override');
    buf.writeln(
        '  List<McpToolDefinition> get tools => $listName;');
    buf.writeln();
    buf.writeln('  @override');
    buf.writeln(
        '  Future<McpToolResult?> dispatch(McpRequest request) async {');
    buf.writeln('    switch (request.toolName) {');
    for (final tool in _tools) {
      buf.writeln(
          "      case '${tool.fieldName}':");
      buf.writeln(
          '        return _handle${ReCase(tool.fieldName).pascalCase}(request.arguments);');
    }
    buf.writeln('      default:');
    buf.writeln('        return null;');
    buf.writeln('    }');
    buf.writeln('  }');

    // HTTP proxy handler methods.
    for (final tool in _tools) {
      buf.writeln();
      _writeHandlerMethod(buf, tool);
    }

    buf.writeln('}');
  }

  void _writeHandlerMethod(StringBuffer buf, _ToolInfo tool) {
    final methodName =
        '_handle${ReCase(tool.fieldName).pascalCase}';
    final httpMethod = tool.method.toUpperCase();

    buf.writeln(
        '  Future<McpToolResult> $methodName(Map<String, dynamic> args) async {');

    // Build the URL with path param interpolation.
    var urlExpr = tool.path;
    for (final p in tool.pathParams) {
      urlExpr = urlExpr.replaceAll('{$p}', "\${Uri.encodeComponent(args['$p'].toString())}");
    }
    buf.writeln("    final url = Uri.parse('\$baseUrl$urlExpr');");

    // Generate the HTTP call based on method.
    if (httpMethod == 'GET' || httpMethod == 'HEAD') {
      buf.writeln('    final response = await _client.get(url);');
    } else if (httpMethod == 'DELETE') {
      buf.writeln('    final response = await _client.delete(url);');
    } else {
      // POST, PUT, PATCH — send non-path params as JSON body.
      buf.writeln('    final body = <String, dynamic>{};');
      buf.writeln('    for (final entry in args.entries) {');
      if (tool.pathParams.isNotEmpty) {
        final pathParamSet =
            tool.pathParams.map((p) => "'$p'").join(', ');
        buf.writeln(
            '      if (!const {$pathParamSet}.contains(entry.key)) {');
        buf.writeln('        body[entry.key] = entry.value;');
        buf.writeln('      }');
      } else {
        buf.writeln('      body[entry.key] = entry.value;');
      }
      buf.writeln('    }');

      if (httpMethod == 'POST') {
        buf.writeln("    final response = await _client.post(url,");
      } else if (httpMethod == 'PUT') {
        buf.writeln("    final response = await _client.put(url,");
      } else {
        buf.writeln("    final response = await _client.patch(url,");
      }
      buf.writeln(
          "        headers: {'Content-Type': 'application/json'},");
      buf.writeln('        body: json.encode(body));');
    }

    // Handle the response.
    buf.writeln(
        '    if (response.statusCode >= 200 && response.statusCode < 300) {');
    buf.writeln('      return McpToolResult.text(response.body);');
    buf.writeln('    } else {');
    buf.writeln('      return McpToolResult.text(');
    buf.writeln(
        "          'HTTP \${response.statusCode}: \${response.body}',");
    buf.writeln('          isError: true);');
    buf.writeln('    }');
    buf.writeln('  }');
  }

  String _escape(String s) => s.replaceAll("'", "\\'");
}
