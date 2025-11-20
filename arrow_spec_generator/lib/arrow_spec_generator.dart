/// Generate OpenAPI 3.0 specifications from Arrow framework code
///
/// This library scans classes annotated with @OpenApiService and @Router,
/// extracts route information from @Route-annotated fields, and generates
/// a complete OpenAPI 3.0 specification.
///
/// ## Usage
///
/// 1. Annotate your service class:
/// ```dart
/// @OpenApiService('api.example.com')
/// @OpenApiMeta('My API', '1.0.0', description: 'API description')
/// @Router()
/// class MyServiceConfig {
///   @Route.get('/users')
///   final getUsers = Handler(getUsersHandler, pipeline);
/// }
/// ```
///
/// 2. Run build_runner:
/// ```bash
/// dart run build_runner build
/// ```
///
/// 3. Generates `openapi.yaml` with complete OpenAPI 3.0 spec
library arrow_spec_generator;

export 'src/generator.dart';
export 'src/spec_builder.dart';
