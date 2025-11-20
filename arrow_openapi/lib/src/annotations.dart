/// Annotations for OpenAPI code generation

/// Annotation to generate an Arrow router from an OpenAPI specification
///
/// Place this annotation on a class to trigger code generation. The generator
/// will read the OpenAPI spec and create a Router with all paths and operations.
///
/// Example:
/// ```dart
/// @GenerateArrowRouter('api/openapi.yaml')
/// class ApiRouter {}
/// ```
///
/// This will generate a `_$ApiRouter` class with a `createRouter()` method.
class GenerateArrowRouter {
  /// Path to the OpenAPI specification file (YAML or JSON)
  /// Can be absolute or relative to the package root
  final String specPath;

  /// Whether to generate handler stubs for operations
  /// If true, generates empty handler functions that you can implement
  final bool generateHandlers;

  /// Whether to generate request/response models from schemas
  /// If true, generates Dart classes for all schemas in the spec
  final bool generateModels;

  /// Prefix for generated model class names
  final String? modelPrefix;

  /// Whether to generate JSON serialization for models
  final bool generateJsonSerializable;

  const GenerateArrowRouter(
    this.specPath, {
    this.generateHandlers = true,
    this.generateModels = true,
    this.modelPrefix,
    this.generateJsonSerializable = true,
  });
}

/// Annotation to customize handler generation for a specific operation
///
/// Use this to override the default handler name or implementation strategy
/// for a specific OpenAPI operation.
///
/// Example:
/// ```dart
/// class ApiRouter {
///   @OpenApiOperation('getUsers', handlerName: 'fetchAllUsers')
///   Future<Response> fetchAllUsers(Request req) async {
///     // Your implementation
///   }
/// }
/// ```
class OpenApiOperation {
  /// The operationId from the OpenAPI spec
  final String operationId;

  /// Custom handler function name (defaults to operationId)
  final String? handlerName;

  /// Whether this handler should be generated as a stub
  final bool generateStub;

  const OpenApiOperation(
    this.operationId, {
    this.handlerName,
    this.generateStub = true,
  });
}
