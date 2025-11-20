# Arrow OpenAPI Code Generator

Generate Arrow framework routers and handlers from OpenAPI 3.0 specifications.

## Features

- **Router Generation**: Automatically creates Arrow routers with all paths and HTTP methods from your OpenAPI spec
- **Type-Safe Models**: Generates Dart classes for all schemas with JSON serialization
- **Handler Stubs**: Creates handler function signatures with parameter extraction
- **RFC 6570 URI Templates**: Uses Arrow's `{param}` format for path parameters
- **Zero Boilerplate**: Write your business logic, let the generator handle routing

## Installation

Add to your `dev_dependencies`:

```yaml
dev_dependencies:
  arrow_openapi:
    path: ../arrow_openapi
  build_runner: ^2.4.0
```

## Usage

### 1. Create an OpenAPI Specification

```yaml
# api/petstore.yaml
openapi: 3.0.0
info:
  title: Pet Store API
  version: 1.0.0

paths:
  /pets/{petId}:
    get:
      operationId: getPetById
      parameters:
        - name: petId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Pet found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Pet'

components:
  schemas:
    Pet:
      type: object
      required:
        - id
        - name
      properties:
        id:
          type: string
        name:
          type: string
```

### 2. Annotate a Class

```dart
import 'package:arrow_openapi/arrow_openapi.dart';

part 'api.openapi.dart';

@GenerateArrowRouter('api/petstore.yaml')
class PetStoreApi {}
```

### 3. Run the Generator

```bash
dart run build_runner build
```

This generates `api.openapi.dart` with:

```dart
// Data Models
class Pet {
  final String id;
  final String name;

  Pet({required this.id, required this.name});

  factory Pet.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}

// Handler Typedef
typedef GetPetByIdHandler = Future<Response> Function(Request req);

// Router Factory
class $PetStoreApi {
  static Router createRouter({
    GetPetByIdHandler? getPetById,
  }) {
    final router = Router();
    if (getPetById != null) {
      router.get('/pets/{petId}', getPetById);
    }
    return router;
  }
}

// Handler Stub
Future<Response> getPetById(Request req) async {
  final petId = req.params.get('petId');
  // TODO: Implement getPetById
  return req.respond.serverError(msg: 'Not implemented');
}
```

### 4. Implement Your Handlers

```dart
Future<Response> getPetById(Request req) async {
  final petId = req.params.get('petId');

  final pet = await database.findPet(petId);
  if (pet == null) {
    return req.respond.notFound(msg: 'Pet not found');
  }

  return req.respond.ok(data: pet.toJson());
}
```

### 5. Create Your Server

```dart
import 'package:arrow/arrow.dart';
import 'api.openapi.dart';

void main() async {
  final router = $PetStoreApi.createRouter(
    getPetById: getPetById,
  );

  final app = Arrow();
  await app.run(() => router, port: 8080);
}
```

## Configuration Options

```dart
@GenerateArrowRouter(
  'api/openapi.yaml',
  // Generate handler stub functions
  generateHandlers: true,

  // Generate model classes from schemas
  generateModels: true,

  // Add prefix to model class names
  modelPrefix: 'Api',

  // Generate fromJson/toJson methods
  generateJsonSerializable: true,
)
```

## Path Parameter Format

Arrow uses RFC 6570 URI Template format (`/users/{id}`), which matches the OpenAPI 3.0 format. The generator automatically converts paths correctly.

## What Gets Generated

### Models
- Class definitions for all `components/schemas`
- Constructor with required/optional parameters
- `fromJson()` factory constructor
- `toJson()` method
- Nested object and array support
- `$ref` reference resolution

### Handlers
- Type-safe handler typedefs for each operation
- Parameter extraction (path, query, header)
- Request body parsing
- Response type documentation
- Stub implementations

### Router
- All HTTP methods (GET, POST, PUT, DELETE, PATCH)
- Path parameter mapping
- Named handler parameters
- Conditional route registration

## Integration with Arrow Framework

The generated code is fully compatible with Arrow:

- Uses `Future<Response> Handler(Request req)` signature
- Uses `req.params.get()` for path parameters
- Uses `req.respond.ok()` / `.notFound()` / etc. for responses
- Uses `{param}` format for routes (RFC 6570)
- Supports middleware and router groups

## Development

To work on this generator:

```bash
cd arrow_openapi
dart pub get
dart test
```

## Architecture

```
arrow_openapi/
├── lib/
│   ├── arrow_openapi.dart          # Public API
│   └── src/
│       ├── annotations.dart         # @GenerateArrowRouter annotation
│       ├── generator.dart           # Main generator (source_gen)
│       ├── openapi_parser.dart      # OpenAPI spec parser
│       └── router_builder.dart      # Arrow code builder
├── build.yaml                       # Builder configuration
└── example/
    ├── petstore.yaml               # Example OpenAPI spec
    └── example.dart                # Usage example
```

## Future Enhancements

- [ ] Validation generation (based on OpenAPI constraints)
- [ ] Authentication/security scheme support
- [ ] Request body validation
- [ ] Response schema validation
- [ ] Custom template support
- [ ] OpenAPI 3.1 support
- [ ] Generate OpenAPI spec from Arrow routers (reverse generation)

## License

Same as Arrow framework - see LICENSE file.
