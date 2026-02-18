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

    buf.writeln('/// Generated dispatcher for $serverName MCP tools.');
    buf.writeln('///');
    buf.writeln('/// The [dispatch] method provides a stub dispatch-by-name switch.');
    buf.writeln(
        '/// The HTTP transport layer is intentionally left as an extension point.');
    buf.writeln('class $className extends McpDispatcher {');
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

    // Stub handler methods.
    for (final tool in _tools) {
      buf.writeln();
      buf.writeln(
          '  /// Stub for ${tool.method} ${tool.path} — wire HTTP transport or direct handler.');
      buf.writeln(
          '  Future<McpToolResult> _handle${ReCase(tool.fieldName).pascalCase}(Map<String, dynamic> args) async {');
      buf.writeln('    return McpToolResult.text(');
      buf.writeln(
          "      'Not implemented: ${tool.method} ${tool.path}',");
      buf.writeln('      isError: true,');
      buf.writeln('    );');
      buf.writeln('  }');
    }

    buf.writeln('}');
  }

  String _escape(String s) => s.replaceAll("'", "\\'");
}
