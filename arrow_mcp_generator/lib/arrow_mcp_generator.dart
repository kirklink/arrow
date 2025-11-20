/// Generate MCP (Model Context Protocol) servers from Arrow routes
///
/// This library scans Arrow service classes and generates MCP servers that
/// expose your API endpoints as AI-callable tools. Write your API once,
/// get automatic AI integration!
///
/// ## Usage
///
/// 1. Annotate your Arrow routes:
/// ```dart
/// @OpenApiService('api.example.com')
/// @McpServer('my-api', description: 'My API for AI')
/// @Router()
/// class ServiceConfig {
///   @Route.get('/users/{id}')
///   @McpTool(description: 'Get user by ID')
///   final getUser = Handler(getUserHandler, pipeline);
/// }
/// ```
///
/// 2. Run build_runner:
/// ```bash
/// dart run build_runner build
/// ```
///
/// 3. Generated `mcp_server.dart` can be run as MCP server
///
/// 4. Configure in claude_desktop_config.json:
/// ```json
/// {
///   "mcpServers": {
///     "my-api": {
///       "command": "dart",
///       "args": ["run", "mcp_server.dart"]
///     }
///   }
/// }
/// ```
library arrow_mcp_generator;

export 'src/generator.dart';
export 'src/mcp_server_builder.dart';
