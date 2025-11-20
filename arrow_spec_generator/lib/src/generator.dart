import 'dart:async';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';

import 'spec_builder.dart';

/// Generator that creates OpenAPI specs from Arrow service classes
class OpenApiSpecGenerator extends Generator {
  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) async {
    // Find all classes with @Router annotation
    final routerClasses = <ClassElement>[];

    for (final element in library.allElements) {
      if (element is ClassElement) {
        // Check for Router annotation
        var hasRouter = false;
        for (final meta in element.metadata) {
          try {
            final value = meta.computeConstantValue();
            final typeName = value?.type?.getDisplayString(withNullability: false);
            if (typeName == 'Router') {
              hasRouter = true;
              break;
            }
          } catch (e) {
            // Skip if we can't compute the annotation value
            continue;
          }
        }

        if (hasRouter) {
          routerClasses.add(element);
        }
      }
    }

    if (routerClasses.isEmpty) {
      return null; // No router classes found
    }

    // Build OpenAPI spec
    final specBuilder = OpenApiSpecBuilder();

    for (final routerClass in routerClasses) {
      // Extract @OpenApiService annotation
      for (final meta in routerClass.metadata) {
        try {
          final value = meta.computeConstantValue();
          final typeName = value?.type?.getDisplayString(withNullability: false);

          if (typeName == 'OpenApiService') {
            final backend = value?.getField('backend')?.toStringValue() ?? '';
            if (backend.isNotEmpty) {
              specBuilder.setServer(backend);
            }
          } else if (typeName == 'OpenApiMeta') {
            final title = value?.getField('title')?.toStringValue() ?? 'API';
            final version = value?.getField('version')?.toStringValue() ?? '1.0.0';
            final description = value?.getField('description')?.toStringValue();
            specBuilder.setInfo(title, version, description: description);
          }
        } catch (e) {
          continue;
        }
      }

      // Extract routes from Handler fields with @Route annotations
      for (final field in routerClass.fields) {
        for (final meta in field.metadata) {
          try {
            final value = meta.computeConstantValue();
            final typeName = value?.type?.getDisplayString(withNullability: false);

            if (typeName == 'Route') {
              final method = value?.getField('method')?.toStringValue() ?? 'GET';
              final path = value?.getField('path')?.toStringValue() ?? '/';

              specBuilder.addRoute(
                method: method,
                path: path,
                operationId: field.name,
                summary: 'Handler: ${field.name}',
              );
            }
          } catch (e) {
            continue;
          }
        }
      }
    }

    // Generate YAML
    return specBuilder.buildYaml();
  }
}

/// Builder function for build.yaml
Builder openApiSpecBuilder(BuilderOptions options) {
  return LibraryBuilder(
    OpenApiSpecGenerator(),
    generatedExtension: '.openapi.yaml',
  );
}
