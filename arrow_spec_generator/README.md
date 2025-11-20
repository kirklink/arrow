# Arrow OpenAPI Spec Generator

**Code-First OpenAPI Generation**: Annotate your Arrow routes and automatically generate OpenAPI 3.0 specifications.

## Overview

This is the **reverse** of typical OpenAPI code generation - instead of generating code from specs, we generate specs from your working Arrow code! Write your routes in Dart with type safety, then automatically produce API documentation.

## Why Code-First?

✅ **Code is the source of truth** - Your implementation drives the spec
✅ **Type-safe development** - Dart compiler catches errors
✅ **Zero boilerplate** - Just add annotations to existing routes
✅ **Always in sync** - Spec regenerates with your code
✅ **Swagger UI ready** - Use generated spec for interactive docs

## Installation

Add to your `dev_dependencies`:

```yaml
dev_dependencies:
  arrow_spec_generator:
    path: ../arrow_spec_generator
  build_runner: ^2.4.0
```

## Usage

### 1. Annotate Your Service Class

```dart
import 'package:arrow/arrow.dart';
import 'package:arrow/annotations.dart';

@OpenApiService('api.example.com')
@OpenApiMeta(
  'My API',
  '1.0.0',
  description: 'A REST API built with Arrow',
)
@Router()
class ServiceConfig {
  @Route.get('/health')
  final healthCheck = Handler(healthCheckHandler, corePipeline);

  @Route.get('/users')
  final getUsers = Handler(getUsersHandler, corePipeline);

  @Route.get('/users/{id}')
  final getUser = Handler(getUserHandler, corePipeline);

  @Route.post('/users')
  final createUser = Handler(createUserHandler, corePipeline);

  static final \$router = buildRouter(notFoundPipeline: corePipeline);
}
```

### 2. Run the Generator

```bash
dart run build_runner build
```

### 3. Get Your OpenAPI Spec

Generates `openapi.yaml`:

```yaml
openapi: 3.0.0
info:
  title: My API
  version: 1.0.0
  description: A REST API built with Arrow
servers:
  - url: https://api.example.com
paths:
  /health:
    get:
      operationId: healthCheck
      summary: Handler: healthCheck
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: object
  /users:
    get:
      operationId: getUsers
      summary: Handler: getUsers
      responses:
        '200':
          description: Successful response
  /users/{id}:
    get:
      operationId: getUser
      summary: Handler: getUser
      responses:
        '200':
          description: Successful response
    post:
      operationId: createUser
      summary: Handler: createUser
      responses:
        '200':
          description: Successful response
```

## Annotations

### @OpenApiService(backend)

Specifies the API server URL.

```dart
@OpenApiService('api.example.com')  // Becomes https://api.example.com
```

### @OpenApiMeta(title, version, ...)

API metadata for the `info` section.

```dart
@OpenApiMeta(
  'Pet Store API',
  '2.0.0',
  description: 'Manage your pets',
  termsOfService: 'https://example.com/terms',
  contact: OpenApiContact(
    name: 'API Support',
    email: 'support@example.com',
  ),
  license: OpenApiLicense('MIT'),
)
```

### @Route.get(path) / @Route.post(path)

Mark Handler fields as API endpoints.

```dart
@Route.get('/items/{itemId}')
final getItem = Handler(getItemHandler, pipeline);

@Route.post('/items')
final createItem = Handler(createItemHandler, pipeline);

@Route.put('/items/{itemId}')
final updateItem = Handler(updateItemHandler, pipeline);

@Route.delete('/items/{itemId}')
final deleteItem = Handler(deleteItemHandler, pipeline);
```

### @Router()

Marks the class as containing route definitions.

```dart
@Router()
class ApiConfig {
  // Routes here
}
```

## Advanced Usage

### Multiple Services

You can have multiple service classes in different files. The generator will scan all classes with `@Router` and produce separate specs or combine them.

### Custom Pipelines

Routes can have different middleware pipelines:

```dart
@Route.get('/public/data')
final publicData = Handler(handler, publicPipeline);

@Route.get('/admin/users')
final adminUsers = Handler(handler, adminPipeline);
```

### Path Parameters

Use RFC 6570 URI Template format (same as OpenAPI):

```dart
@Route.get('/users/{userId}/posts/{postId}')
final getUserPost = Handler(handler, pipeline);
```

## Generated Output

The generator creates:

- **openapi.yaml** - Complete OpenAPI 3.0 specification
- Can be used with Swagger UI, Postman, API clients
- Includes all paths, methods, and operationIds
- Server URL from @OpenApiService
- API metadata from @OpenApiMeta

## Integration with Tools

### Swagger UI

```bash
# Serve generated spec with Swagger UI
docker run -p 8081:8080 -e SWAGGER_JSON=/openapi.yaml \
  -v $(pwd)/openapi.yaml:/openapi.yaml \
  swaggerapi/swagger-ui
```

### Postman

Import `openapi.yaml` directly into Postman for API testing.

### Code Generation

Use the generated spec with other tools:
- Generate TypeScript clients
- Generate mobile SDK
- Generate API mocks

## Architecture

```
Your Dart Code (with annotations)
         ↓
   [Analyzer scans annotations]
         ↓
   [Extract route metadata]
         ↓
   [OpenApiSpecBuilder]
         ↓
   openapi.yaml
```

## Design Philosophy

**Code is King**: Your Arrow routes are the single source of truth. The spec is a reflection of your actual implementation, not a contract you have to match.

**Minimal Annotations**: Just mark what matters - service info and routes. Everything else is inferred from your code.

**Developer Experience**: No context switching between YAML and Dart. Write routes, add annotations, done.

## Future Enhancements

- [ ] Extract request/response models from handler signatures
- [ ] Generate schema definitions from Dart classes with @OpenApiModel
- [ ] Support @OpenApiField for controlling serialization
- [ ] Extract parameter descriptions from doc comments
- [ ] Support security schemes (@OpenApiAuth)
- [ ] Generate response examples
- [ ] Support multiple response types per status code

## Comparison with Other Approaches

**arrow_openapi** (spec-first):
- Write OpenAPI spec first
- Generate Arrow routes and models
- Good for: Implementing existing API contracts

**arrow_spec_generator** (code-first - this package):
- Write Arrow routes first
- Generate OpenAPI spec
- Good for: New APIs, documentation, API-first development

Both approaches are complementary and can coexist in the same ecosystem!

## License

Same as Arrow framework - see LICENSE file.
