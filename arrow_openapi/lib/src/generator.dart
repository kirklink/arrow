import 'dart:async';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;
import 'annotations.dart';
import 'openapi_parser.dart';
import 'router_builder.dart';

/// Generator for creating Arrow routers from OpenAPI specifications
///
/// This generator reads OpenAPI specs and generates:
/// - Router configuration with all paths and methods
/// - Handler function signatures
/// - Request/Response model classes
/// - JSON serialization code
class ArrowOpenApiGenerator extends GeneratorForAnnotation<GenerateArrowRouter> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@GenerateArrowRouter can only be applied to classes',
        element: element,
      );
    }

    // Read annotation parameters
    final specPath = annotation.read('specPath').stringValue;
    final generateHandlers = annotation.read('generateHandlers').boolValue;
    final generateModels = annotation.read('generateModels').boolValue;
    final modelPrefix = annotation.read('modelPrefix').literalValue as String?;
    final generateJsonSerializable =
        annotation.read('generateJsonSerializable').boolValue;

    // Resolve the spec file path
    final resolvedPath = await _resolveSpecPath(specPath, buildStep);
    if (resolvedPath == null) {
      throw InvalidGenerationSourceError(
        'Could not find OpenAPI spec at: $specPath',
        element: element,
      );
    }

    // Parse the OpenAPI specification
    final specContent = await buildStep.readAsString(resolvedPath);
    final spec = _parseOpenApiSpec(specContent, resolvedPath.path);

    // Parse the OpenAPI document into our internal model
    final parser = OpenApiParser();
    final apiDoc = parser.parse(spec);

    // Build the router code
    final builder = RouterBuilder(
      className: element.name,
      apiDoc: apiDoc,
      generateHandlers: generateHandlers,
      generateModels: generateModels,
      modelPrefix: modelPrefix,
      generateJsonSerializable: generateJsonSerializable,
    );

    return builder.build();
  }

  /// Resolve the spec path relative to the package
  Future<AssetId?> _resolveSpecPath(String specPath, BuildStep buildStep) async {
    final inputId = buildStep.inputId;

    // Try relative to the input file
    final relativeToFile = AssetId(
      inputId.package,
      p.normalize(p.join(p.dirname(inputId.path), specPath)),
    );
    if (await buildStep.canRead(relativeToFile)) {
      return relativeToFile;
    }

    // Try relative to package root
    final relativeToRoot = AssetId(inputId.package, specPath);
    if (await buildStep.canRead(relativeToRoot)) {
      return relativeToRoot;
    }

    // Try with common prefixes
    for (final prefix in ['lib/', 'api/', 'specs/']) {
      final withPrefix = AssetId(inputId.package, p.join(prefix, specPath));
      if (await buildStep.canRead(withPrefix)) {
        return withPrefix;
      }
    }

    return null;
  }

  /// Parse OpenAPI spec from YAML or JSON
  dynamic _parseOpenApiSpec(String content, String path) {
    if (path.endsWith('.yaml') || path.endsWith('.yml')) {
      return loadYaml(content);
    } else if (path.endsWith('.json')) {
      // The yaml package can also parse JSON
      return loadYaml(content);
    } else {
      throw InvalidGenerationSourceError(
        'OpenAPI spec must be .yaml, .yml, or .json file',
      );
    }
  }
}

/// Builder function for build.yaml
Builder arrowOpenApiBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    [ArrowOpenApiGenerator()],
    'arrow_openapi',
  );
}
