/// OpenAPI 3.0 code generator for Arrow framework
///
/// This library provides annotations and utilities for generating Arrow
/// routers and handlers from OpenAPI 3.0 specifications.
///
/// ## Usage
///
/// 1. Add arrow_openapi to your dev_dependencies
/// 2. Create an OpenAPI spec (YAML or JSON)
/// 3. Annotate a class with @GenerateArrowRouter
/// 4. Run build_runner to generate the router code
///
/// Example:
/// ```dart
/// import 'package:arrow_openapi/arrow_openapi.dart';
///
/// @GenerateArrowRouter('openapi.yaml')
/// class ApiRouter {}
/// ```
library arrow_openapi;

export 'src/annotations.dart';
export 'src/generator.dart';
