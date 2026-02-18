/// Marks a class for MCP server code generation.
///
/// The annotated class contains fields annotated with [McpTool] that define
/// which Arrow route handlers to expose as MCP tools.
///
/// ```dart
/// @McpServer('user-api', description: 'User management API')
/// class UserServiceMcp {
///   @McpTool(description: 'Get all users', method: 'GET', path: '/users')
///   final getUsers = getAllUsersHandler;
/// }
/// ```
class McpServer {
  /// Machine-readable name for the MCP server.
  final String name;

  /// Human-readable description of what this server provides.
  final String? description;

  /// Version string for the MCP server. Defaults to '1.0.0'.
  final String version;

  const McpServer(this.name, {this.description, this.version = '1.0.0'});
}

/// Marks a field as an MCP tool, providing both route metadata and
/// MCP tool metadata for code generation.
///
/// The field name becomes the tool name. The annotation captures the
/// HTTP method and path (since Arrow uses imperative routing, not
/// annotation-driven routing) alongside MCP-specific metadata.
///
/// ```dart
/// @McpTool(
///   description: 'Get user by ID',
///   method: 'GET',
///   path: '/users/{id}',
///   parameters: {'id': 'The unique identifier of the user'},
/// )
/// final getUser = getUserByIdHandler;
/// ```
class McpTool {
  /// Human-readable description of what this tool does.
  /// This is what the LLM sees when deciding which tool to call.
  final String description;

  /// HTTP method: 'GET', 'POST', 'PUT', 'DELETE', 'PATCH'.
  final String method;

  /// Route path with {param} placeholders, e.g. '/users/{id}'.
  final String path;

  /// Map of parameter names to their descriptions.
  /// Path parameters are auto-detected from {param} in the path.
  /// Additional entries describe query params or body fields.
  final Map<String, String> parameters;

  const McpTool({
    required this.description,
    required this.method,
    required this.path,
    this.parameters = const {},
  });
}
