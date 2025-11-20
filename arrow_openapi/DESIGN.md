# Arrow OpenAPI Code Generator - Design Document

## Overview

This package generates Arrow framework code from OpenAPI 3.0 specifications. It's a sibling package to avoid build system conflicts and circular dependencies.

## Problem Statement

Writing REST APIs involves a lot of boilerplate:
- Manually defining routes for each endpoint
- Creating model classes for request/response bodies
- Writing JSON serialization code
- Keeping documentation in sync with code

OpenAPI specs provide a single source of truth, but manually implementing them is error-prone.

## Solution

Use Dart's `build_runner` and `source_gen` to automatically generate:
1. **Type-safe models** - Dart classes from OpenAPI schemas
2. **Router configuration** - All paths/methods wired up correctly
3. **Handler signatures** - Function types with proper parameters
4. **Stub implementations** - Starting point for business logic

## Architecture

### Package Structure

```
arrow_openapi/          # Sibling to main arrow package
├── lib/
│   ├── arrow_openapi.dart              # Public API
│   └── src/
│       ├── annotations.dart             # @GenerateArrowRouter
│       ├── generator.dart               # source_gen integration
│       ├── openapi_parser.dart          # Parse OpenAPI YAML/JSON
│       └── router_builder.dart          # Generate Arrow code
├── build.yaml                           # Builder configuration
└── example/
    └── petstore.yaml                   # Example spec
```

### Code Generation Flow

```
OpenAPI Spec (YAML/JSON)
         ↓
    [Parser]                   Parse spec into internal model
         ↓
  ApiDocument                  Structured representation
         ↓
 [RouterBuilder]               Generate Dart code
         ↓
  Generated .dart file         Models + Router + Handlers
```

### Key Components

#### 1. Annotations (`annotations.dart`)

```dart
@GenerateArrowRouter('api/spec.yaml')
class MyApi {}
```

Configuration options:
- `specPath`: Path to OpenAPI spec file
- `generateHandlers`: Whether to generate handler stubs
- `generateModels`: Whether to generate model classes
- `modelPrefix`: Optional prefix for model class names
- `generateJsonSerializable`: Include fromJson/toJson

#### 2. Generator (`generator.dart`)

Implements `GeneratorForAnnotation<GenerateArrowRouter>`:
- Triggered when `@GenerateArrowRouter` is found
- Reads the OpenAPI spec file
- Parses YAML/JSON
- Delegates to RouterBuilder
- Outputs `.openapi.dart` file

Uses `SharedPartBuilder` to integrate with source_gen.

#### 3. Parser (`openapi_parser.dart`)

Converts OpenAPI spec to internal model:

```dart
OpenAPI Spec → ApiDocument
                  ├── ApiInfo (title, version, description)
                  ├── List<ApiPath>
                  │     └── List<ApiOperation>
                  │           ├── method, operationId
                  │           ├── parameters
                  │           ├── requestBody
                  │           └── responses
                  └── Map<String, ApiSchema> (components/schemas)
```

Key features:
- Handles `$ref` references
- Extracts path/query/header parameters
- Parses request/response schemas
- Generates operationIds if missing

#### 4. Router Builder (`router_builder.dart`)

Generates Arrow-specific Dart code:

**Models Generation:**
```dart
class Pet {
  final String id;
  final String name;
  final String? tag;

  Pet({required this.id, required this.name, this.tag});

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as String,
      name: json['name'] as String,
      tag: json['tag'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tag': tag,
    };
  }
}
```

**Handler Typedefs:**
```dart
typedef GetPetByIdHandler = Future<Response> Function(Request req);
```

**Router Factory:**
```dart
class $MyApi {
  static Router createRouter({
    GetPetByIdHandler? getPetById,
    // ... other handlers
  }) {
    final router = Router();

    if (getPetById != null) {
      router.get('/pets/{petId}', getPetById);
    }

    return router;
  }
}
```

**Handler Stubs:**
```dart
/// GET /pets/{petId}
/// Info for a specific pet
///
/// Parameters:
/// - petId (path): The id of the pet to retrieve
Future<Response> getPetById(Request req) async {
  final petId = req.params.get('petId');
  // TODO: Implement getPetById
  return req.respond.serverError(msg: 'Not implemented');
}
```

## Design Decisions

### 1. Sibling Package Structure

**Why:** Avoid circular dependencies and build conflicts
- The generator depends on `arrow` (for types)
- Projects using arrow_openapi depend on both packages
- Keeps code generation separate from runtime code

### 2. RFC 6570 URI Templates

**Why:** Arrow uses `{param}` format (matches OpenAPI)
- OpenAPI: `/pets/{petId}`
- Arrow: `/pets/{petId}` ✓
- Express style `/pets/:petId` would need conversion

No conversion needed! OpenAPI and Arrow use the same format.

### 3. Optional Handler Pattern

**Why:** Allow incremental implementation
```dart
$MyApi.createRouter(
  getPetById: myImplementation,
  // Other handlers optional - routes not registered if null
)
```

Benefits:
- Implement endpoints one at a time
- Missing handlers = missing routes (not runtime errors)
- Type-safe at compile time

### 4. Part Files (`.openapi.dart`)

**Why:** Keep generated code separate but accessible
- Generated code in separate file
- Use `part` directive to include
- Clear separation between written and generated code

### 5. Stub Generation

**Why:** Provide starting point with proper signature
- Correct parameter extraction
- Proper return type
- Documentation from OpenAPI spec
- Reduces copy-paste errors

## Type Mapping

OpenAPI Type → Dart Type:
- `string` → `String`
- `integer` → `int`
- `number` → `double`
- `boolean` → `bool`
- `array` → `List<T>`
- `object` → `Map<String, dynamic>` or generated class
- `$ref` → Generated model class
- nullable → `T?`

## Example Usage

### Input: OpenAPI Spec

```yaml
paths:
  /users/{userId}:
    get:
      operationId: getUserById
      parameters:
        - name: userId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'

components:
  schemas:
    User:
      type: object
      required: [id, name]
      properties:
        id: {type: string}
        name: {type: string}
        email: {type: string}
```

### Output: Generated Code

```dart
// Models
class User {
  final String id;
  final String name;
  final String? email;

  User({required this.id, required this.name, this.email});

  factory User.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}

// Router Factory
class $UsersApi {
  static Router createRouter({
    GetUserByIdHandler? getUserById,
  }) {
    final router = Router();
    if (getUserById != null) {
      router.get('/users/{userId}', getUserById);
    }
    return router;
  }
}

// Handler Stub
Future<Response> getUserById(Request req) async {
  final userId = req.params.get('userId');
  // TODO: Implement
}
```

### Your Implementation

```dart
Future<Response> getUserById(Request req) async {
  final userId = req.params.get('userId');

  final user = await database.users.findById(userId);
  if (user == null) {
    return req.respond.notFound(msg: 'User not found');
  }

  return req.respond.ok(data: user.toJson());
}

void main() async {
  final router = $UsersApi.createRouter(
    getUserById: getUserById,
  );

  final app = Arrow();
  await app.run(() => router, port: 8080);
}
```

## Future Enhancements

### 1. Validation Generation
Generate validators from OpenAPI constraints:
- `minimum`, `maximum` for numbers
- `minLength`, `maxLength` for strings
- `pattern` for regex validation
- `enum` for allowed values

### 2. Security Schemes
Generate middleware for OpenAPI security:
- `apiKey` → Header/query validation
- `http` → Bearer token validation
- `oauth2` → OAuth flow integration

### 3. Reverse Generation
Generate OpenAPI spec from Arrow routers:
- Analyze router structure
- Extract parameter types
- Generate schemas from classes
- Keep spec in sync with code

### 4. Custom Templates
Allow users to customize generated code:
- Mustache/Jinja templates
- Custom naming conventions
- Framework-specific adaptations

### 5. OpenAPI 3.1 Support
- JSON Schema 2020-12
- Webhooks
- Improved `oneOf`/`anyOf` handling

## Testing Strategy

1. **Unit Tests**: Test each component in isolation
   - Parser: Various OpenAPI specs → ApiDocument
   - Builder: ApiDocument → Generated code strings
   - Type mapping: OpenAPI types → Dart types

2. **Integration Tests**: End-to-end generation
   - Real OpenAPI specs
   - Run build_runner
   - Verify generated code compiles
   - Test generated routers work

3. **Golden Tests**: Compare generated output
   - Store expected output
   - Compare with actual generation
   - Catch unintended changes

## Performance Considerations

- **Caching**: build_runner caches results
- **Incremental**: Only regenerate when spec changes
- **Lazy**: Routes only registered if handler provided
- **AOT Ready**: Generated code is AOT-compatible

## Limitations

1. Not all OpenAPI features supported initially:
   - No `oneOf`/`anyOf`/`allOf` in models yet
   - Limited validation generation
   - No security scheme generation

2. Requires spec to follow conventions:
   - Descriptive `operationId` values
   - Schemas in `components/schemas`
   - Standard HTTP status codes

3. Generated stubs need implementation:
   - Business logic not generated
   - Database access user-provided
   - Validation optional

## Conclusion

This design provides a solid foundation for OpenAPI code generation in Arrow. The architecture is extensible, the generated code is type-safe, and the developer experience is streamlined.

By keeping it as a separate package, we avoid build system complexity while providing powerful code generation capabilities.
