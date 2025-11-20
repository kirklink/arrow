# Arrow MCP Generator

Generate MCP (Model Context Protocol) servers from your Arrow routes, enabling AI assistants like Claude to interact with your API.

## What is MCP?

[Model Context Protocol](https://modelcontextprotocol.io) is a standard for exposing tools and resources to AI assistants. With Arrow MCP Generator, you write your API once and automatically get an MCP server that AI assistants can use.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  arrow: any
  mcp_server: ^0.1.0

dev_dependencies:
  arrow_mcp_generator: any
  build_runner: ^2.4.0
```

## Usage

### 1. Annotate Your Routes

```dart
import 'package:arrow/arrow.dart';

Future<Response> getUserHandler(Request req) async {
  final id = req.params.get('id');
  // Fetch and return user data
  return req.respond.ok(data: {'id': id, 'name': 'User $id'});
}

Future<Response> createUserHandler(Request req) async {
  // Create user and return result
  return req.respond.ok(data: {'id': '123', 'created': true});
}

@McpServer('my-api', description: 'My API for AI assistants')
@RouterConfig()
class ServiceConfig {
  @RouteHandler.get('/users/{id}')
  @McpTool(
    description: 'Retrieve user information by ID',
    parameters: {
      'id': 'The unique identifier of the user',
    },
  )
  final getUser = getUserHandler;

  @RouteHandler.post('/users')
  @McpTool(
    description: 'Create a new user',
    parameters: {
      'name': 'The user\'s full name',
      'email': 'The user\'s email address',
    },
  )
  final createUser = createUserHandler;
}
```

### 2. Generate MCP Server

```bash
dart run build_runner build
```

This generates a file like `service_config.mcp.dart` with a complete MCP server implementation.

### 3. Run the MCP Server

The generated file includes a `main()` function:

```bash
dart run lib/service_config.mcp.dart
```

### 4. Configure Claude Desktop

Add to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "my-api": {
      "command": "dart",
      "args": ["run", "/path/to/your/lib/service_config.mcp.dart"]
    }
  }
}
```

## How It Works

The generator:

1. Scans for `@Router()` classes with `@McpServer()` annotation
2. Extracts all `@Route.*()` handlers with `@McpTool()` metadata
3. Generates an MCP server that:
   - Exposes each route as a tool to AI assistants
   - Includes parameter descriptions and validation
   - Makes HTTP calls to your actual API
   - Returns formatted responses

## Example Generated Code

From the annotations above, the generator creates:

```dart
class MyApiServer extends McpServer {
  final String baseUrl = 'http://localhost:3000';

  @override
  List<Tool> get tools => [
    Tool(
      name: 'getUser',
      description: 'Retrieve user information by ID',
      inputSchema: {
        'type': 'object',
        'properties': {
          'id': {'type': 'string', 'description': 'The unique identifier of the user'},
        },
        'required': ['id'],
      },
    ),
    Tool(
      name: 'createUser',
      description: 'Create a new user',
      inputSchema: {
        'type': 'object',
        'properties': {
          'name': {'type': 'string', 'description': 'The user\'s full name'},
          'email': {'type': 'string', 'description': 'The user\'s email address'},
        },
        'required': ['name', 'email'],
      },
    ),
  ];

  @override
  Future<ToolResult> callTool(String name, Map<String, dynamic> args) async {
    // Routes calls to actual API endpoints
  }
}
```

## Configuration

### Custom Base URL

By default, the generator assumes your API runs at `http://localhost:3000`. To customize:

```dart
@McpServer('my-api',
  description: 'My API',
  baseUrl: 'https://api.production.com'  // TODO: Add this feature
)
```

### Excluding Routes

Not all routes need to be exposed to AI. Simply don't add `@McpTool()` to routes you want to keep private.

## Benefits

- **Write Once**: Define routes, OpenAPI specs, and MCP servers from the same code
- **Type Safety**: Generated code is fully type-safe
- **Automatic Updates**: Regenerate when routes change
- **AI Integration**: Enable AI assistants to use your API with zero additional code

## Complete Example

See [example/](../example/) for a full working implementation.
