/// MCP (Model Context Protocol) annotations for Arrow
///
/// Use these annotations alongside Arrow route annotations to generate
/// MCP servers that expose your API to AI assistants.

/// Annotation to mark a service class for MCP server generation
///
/// Use alongside @Router() to generate an MCP server from your routes.
///
/// Example:
/// ```dart
/// @McpServer('my-api', description: 'My API for AI assistants')
/// @Router()
/// class ServiceConfig {
///   // Routes here
/// }
/// ```
class McpServer {
  /// Name of the MCP server
  final String name;

  /// Description of what this server provides
  final String? description;

  const McpServer(this.name, {this.description});
}

/// Annotation to provide metadata for MCP tool generation
///
/// Add to Handler fields alongside @Route to customize the MCP tool.
///
/// Example:
/// ```dart
/// @Route.get('/users/{id}')
/// @McpTool(
///   description: 'Retrieve user information by ID',
///   parameters: {
///     'id': 'The unique identifier of the user',
///   },
/// )
/// final getUser = Handler(getUserHandler, pipeline);
/// ```
class McpTool {
  /// Description of what this tool does
  final String description;

  /// Map of parameter names to their descriptions
  /// These will be included in the tool's input schema
  final Map<String, String>? parameters;

  const McpTool({
    required this.description,
    this.parameters,
  });
}
