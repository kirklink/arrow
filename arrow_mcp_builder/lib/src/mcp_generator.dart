import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'mcp_code_writer.dart';

const _mcpServerChecker = TypeChecker.fromUrl(
    'package:arrow/src/mcp/annotations.dart#McpServer');

const _mcpToolChecker = TypeChecker.fromUrl(
    'package:arrow/src/mcp/annotations.dart#McpTool');

class McpServerGenerator extends Generator {
  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) {
    final annotated = library.annotatedWith(_mcpServerChecker);
    if (annotated.isEmpty) return null;

    final buffer = StringBuffer();

    for (final annotatedElement in annotated) {
      final element = annotatedElement.element;
      if (element is! ClassElement) {
        throw InvalidGenerationSourceError(
          '@McpServer can only annotate classes.',
          element: element,
        );
      }

      final annotation = annotatedElement.annotation;
      final serverName = annotation.read('name').stringValue;
      final serverDescription =
          annotation.peek('description')?.stringValue;
      final serverVersion =
          annotation.peek('version')?.stringValue ?? '1.0.0';

      final writer = McpCodeWriter(
        serverName: serverName,
        serverDescription: serverDescription,
        serverVersion: serverVersion,
      );

      // Scan fields for @McpTool.
      for (final field in element.fields) {
        final toolAnnotation = _mcpToolChecker.firstAnnotationOfExact(field);
        if (toolAnnotation == null) continue;

        final reader = ConstantReader(toolAnnotation);
        final description = reader.read('description').stringValue;
        final method = reader.read('method').stringValue;
        final path = reader.read('path').stringValue;

        // Extract parameters map.
        final params = <String, String>{};
        final paramsReader = reader.peek('parameters');
        if (paramsReader != null && !paramsReader.isNull) {
          for (final entry in paramsReader.mapValue.entries) {
            final key = entry.key!.toStringValue()!;
            final value = entry.value!.toStringValue()!;
            params[key] = value;
          }
        }

        // Auto-detect path parameters from {param} syntax.
        final pathParams = RegExp(r'\{([^}]+)\}')
            .allMatches(path)
            .map((m) => m.group(1)!)
            .toList();

        writer.addTool(
          fieldName: field.name!,
          description: description,
          method: method,
          path: path,
          pathParams: pathParams,
          parameters: params,
        );
      }

      buffer.write(writer.build());
    }

    return buffer.isEmpty ? null : buffer.toString();
  }
}
