/// A single tool definition in MCP-compatible format.
///
/// This is the runtime representation of what gets generated from [McpTool].
/// Both the code generator (static) and [McpToolRegistry] (dynamic) produce
/// instances of this class.
class McpToolDefinition {
  /// Tool name (unique within a server).
  final String name;

  /// Human-readable description shown to the LLM.
  final String description;

  /// JSON Schema for the tool's input parameters.
  /// Structure: `{'type': 'object', 'properties': {...}, 'required': [...]}`.
  final Map<String, Object> inputSchema;

  /// HTTP method this tool maps to (GET, POST, etc.).
  /// Null for tools that don't map to HTTP endpoints.
  final String? method;

  /// Route path this tool maps to (e.g. '/users/{id}').
  /// Null for tools that don't map to HTTP endpoints.
  final String? path;

  const McpToolDefinition({
    required this.name,
    required this.description,
    required this.inputSchema,
    this.method,
    this.path,
  });

  /// Serialize to MCP-compatible JSON map.
  Map<String, Object> toJson() => {
        'name': name,
        'description': description,
        'inputSchema': inputSchema,
      };
}

/// Represents an incoming MCP tool call request.
class McpRequest {
  /// The name of the tool being called.
  final String toolName;

  /// The arguments provided by the caller.
  final Map<String, dynamic> arguments;

  const McpRequest({required this.toolName, this.arguments = const {}});
}

/// Result of executing an MCP tool.
class McpToolResult {
  /// The content blocks returned by the tool.
  final List<McpContent> content;

  /// Whether this result represents an error.
  final bool isError;

  const McpToolResult({required this.content, this.isError = false});

  /// Convenience constructor for a simple text result.
  factory McpToolResult.text(String text, {bool isError = false}) =>
      McpToolResult(content: [McpTextContent(text)], isError: isError);

  /// Serialize to MCP-compatible JSON map.
  Map<String, Object> toJson() => {
        'content': content.map((c) => c.toJson()).toList(),
        if (isError) 'isError': true,
      };
}

/// Base class for MCP content blocks.
abstract class McpContent {
  const McpContent();

  /// Serialize to MCP-compatible JSON map.
  Map<String, Object> toJson();
}

/// A text content block.
class McpTextContent extends McpContent {
  final String text;

  const McpTextContent(this.text);

  @override
  Map<String, Object> toJson() => {'type': 'text', 'text': text};
}
