import 'types.dart';
import 'dispatcher.dart';

/// A mutable registry of MCP tools, supporting both static (codegen)
/// and dynamic (runtime) tool definitions.
///
/// This is the key extension point for the Envoy agent framework:
/// it can merge generated tool lists with dynamically registered tools.
///
/// ```dart
/// final registry = McpToolRegistry();
///
/// // Add generated tools from codegen
/// registry.registerDispatcher(UserApiMcpDispatcher());
///
/// // Add dynamic tools at runtime
/// registry.register(
///   McpToolDefinition(name: 'search', description: '...', inputSchema: {}),
///   (args) async => McpToolResult.text('result'),
/// );
/// ```
class McpToolRegistry {
  final Map<String, McpToolDefinition> _tools = {};
  final Map<String, Future<McpToolResult> Function(Map<String, dynamic>)>
      _handlers = {};
  final List<McpDispatcher> _dispatchers = [];

  /// Register a tool with its handler function.
  void register(
    McpToolDefinition tool,
    Future<McpToolResult> Function(Map<String, dynamic> args) handler,
  ) {
    _tools[tool.name] = tool;
    _handlers[tool.name] = handler;
  }

  /// Merge all tools from a generated dispatcher.
  ///
  /// Tool definitions are copied into this registry. Dispatch calls
  /// for those tools are routed through the dispatcher.
  void registerDispatcher(McpDispatcher dispatcher) {
    _dispatchers.add(dispatcher);
    for (final tool in dispatcher.tools) {
      _tools[tool.name] = tool;
    }
  }

  /// All registered tool definitions.
  List<McpToolDefinition> get tools => _tools.values.toList();

  /// Look up a tool by name.
  McpToolDefinition? findTool(String name) => _tools[name];

  /// Dispatch a request to the appropriate handler.
  ///
  /// Checks directly registered handlers first, then falls back to
  /// dispatchers. Returns null if no handler is found.
  Future<McpToolResult?> dispatch(McpRequest request) async {
    // Direct handler takes priority.
    final handler = _handlers[request.toolName];
    if (handler != null) {
      return handler(request.arguments);
    }

    // Fall back to dispatchers.
    for (final dispatcher in _dispatchers) {
      final result = await dispatcher.dispatch(request);
      if (result != null) return result;
    }

    return null;
  }
}
