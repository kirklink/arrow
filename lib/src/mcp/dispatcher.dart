import 'types.dart';

/// Abstract interface for dispatching MCP tool calls.
///
/// The generated code implements this for statically-defined tools.
/// [McpToolRegistry] uses this to merge static and dynamic tool lists.
abstract class McpDispatcher {
  /// All tools available in this dispatcher.
  List<McpToolDefinition> get tools;

  /// Dispatch a tool call by name.
  /// Returns null if the tool name is not recognized.
  Future<McpToolResult?> dispatch(McpRequest request);
}
