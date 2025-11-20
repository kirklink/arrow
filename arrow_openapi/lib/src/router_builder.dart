import 'openapi_parser.dart';

/// Builds Arrow router code from an OpenAPI document
class RouterBuilder {
  final String className;
  final ApiDocument apiDoc;
  final bool generateHandlers;
  final bool generateModels;
  final String? modelPrefix;
  final bool generateJsonSerializable;

  RouterBuilder({
    required this.className,
    required this.apiDoc,
    required this.generateHandlers,
    required this.generateModels,
    this.modelPrefix,
    required this.generateJsonSerializable,
  });

  /// Build the complete generated code
  String build() {
    final buffer = StringBuffer();

    // Header comment
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated from OpenAPI specification');
    buffer.writeln('// API: ${apiDoc.info.title} ${apiDoc.info.version}');
    buffer.writeln();

    // Imports
    _writeImports(buffer);
    buffer.writeln();

    // Generate models if requested
    if (generateModels) {
      _writeModels(buffer);
      buffer.writeln();
    }

    // Generate handler typedefs
    _writeHandlerTypedefs(buffer);
    buffer.writeln();

    // Generate the router factory class
    _writeRouterFactory(buffer);
    buffer.writeln();

    // Generate handler stubs if requested
    if (generateHandlers) {
      _writeHandlerStubs(buffer);
    }

    return buffer.toString();
  }

  void _writeImports(StringBuffer buffer) {
    buffer.writeln("import 'dart:async';");
    buffer.writeln("import 'package:arrow/arrow.dart';");

    if (generateJsonSerializable) {
      buffer.writeln("import 'dart:convert';");
    }
  }

  void _writeModels(StringBuffer buffer) {
    buffer.writeln('// ========== Data Models ==========');
    buffer.writeln();

    for (final entry in apiDoc.schemas.entries) {
      final schemaName = entry.key;
      final schema = entry.value;

      if (schema.type == 'object') {
        _writeModelClass(buffer, schemaName, schema);
        buffer.writeln();
      }
    }
  }

  void _writeModelClass(StringBuffer buffer, String name, ApiSchema schema) {
    final className = _getModelClassName(name);

    buffer.writeln('/// ${schema.properties?.length ?? 0} properties');
    buffer.writeln('class $className {');

    // Properties
    if (schema.properties != null) {
      for (final prop in schema.properties!.entries) {
        final propName = prop.key;
        final propSchema = prop.value;
        final isRequired = schema.required?.contains(propName) ?? false;
        final dartType = _schemaToDartType(propSchema, nullable: !isRequired);

        buffer.writeln('  final $dartType $propName;');
      }
      buffer.writeln();

      // Constructor
      buffer.writeln('  $className({');
      for (final prop in schema.properties!.entries) {
        final propName = prop.key;
        final isRequired = schema.required?.contains(propName) ?? false;
        if (isRequired) {
          buffer.writeln('    required this.$propName,');
        } else {
          buffer.writeln('    this.$propName,');
        }
      }
      buffer.writeln('  });');
      buffer.writeln();

      // fromJson
      if (generateJsonSerializable) {
        buffer.writeln('  factory $className.fromJson(Map<String, dynamic> json) {');
        buffer.writeln('    return $className(');
        for (final prop in schema.properties!.entries) {
          final propName = prop.key;
          final propSchema = prop.value;
          final conversion = _getJsonConversion(propName, propSchema);
          buffer.writeln('      $propName: $conversion,');
        }
        buffer.writeln('    );');
        buffer.writeln('  }');
        buffer.writeln();

        // toJson
        buffer.writeln('  Map<String, dynamic> toJson() {');
        buffer.writeln('    return {');
        for (final prop in schema.properties!.entries) {
          final propName = prop.key;
          buffer.writeln("      '$propName': $propName,");
        }
        buffer.writeln('    };');
        buffer.writeln('  }');
      }
    }

    buffer.writeln('}');
  }

  String _getModelClassName(String name) {
    final prefix = modelPrefix ?? '';
    return '$prefix$name';
  }

  String _schemaToDartType(ApiSchema schema, {bool nullable = false}) {
    String baseType;

    if (schema.ref != null) {
      baseType = _getModelClassName(schema.refName!);
    } else if (schema.type == 'array' && schema.items != null) {
      final itemType = _schemaToDartType(schema.items!, nullable: false);
      baseType = 'List<$itemType>';
    } else {
      switch (schema.type) {
        case 'string':
          baseType = 'String';
          break;
        case 'integer':
          baseType = 'int';
          break;
        case 'number':
          baseType = 'double';
          break;
        case 'boolean':
          baseType = 'bool';
          break;
        case 'object':
          baseType = 'Map<String, dynamic>';
          break;
        default:
          baseType = 'dynamic';
      }
    }

    return nullable ? '$baseType?' : baseType;
  }

  String _getJsonConversion(String propName, ApiSchema schema) {
    if (schema.ref != null) {
      final modelClass = _getModelClassName(schema.refName!);
      return "json['$propName'] != null ? $modelClass.fromJson(json['$propName'] as Map<String, dynamic>) : null";
    } else if (schema.type == 'array' && schema.items != null) {
      if (schema.items!.ref != null) {
        final itemClass = _getModelClassName(schema.items!.refName!);
        return "(json['$propName'] as List?)?.map((e) => $itemClass.fromJson(e as Map<String, dynamic>)).toList()";
      } else {
        final itemType = _schemaToDartType(schema.items!, nullable: false);
        return "(json['$propName'] as List?)?.cast<$itemType>()";
      }
    } else {
      final dartType = _schemaToDartType(schema, nullable: false);
      return "json['$propName'] as $dartType?";
    }
  }

  void _writeHandlerTypedefs(StringBuffer buffer) {
    buffer.writeln('// ========== Handler Function Typedefs ==========');
    buffer.writeln();

    for (final path in apiDoc.paths) {
      for (final op in path.operations) {
        final handlerName = _capitalize(op.operationId);
        buffer.writeln('/// Handler for ${op.method} ${path.path}');
        if (op.summary != null) {
          buffer.writeln('/// ${op.summary}');
        }
        buffer.writeln('typedef ${handlerName}Handler = Future<Response> Function(Request req);');
        buffer.writeln();
      }
    }
  }

  void _writeRouterFactory(StringBuffer buffer) {
    buffer.writeln('// ========== Router Factory ==========');
    buffer.writeln();
    buffer.writeln('/// Factory class for creating the ${apiDoc.info.title} router');
    buffer.writeln('class \$${className} {');
    buffer.writeln('  /// Create a router with all API endpoints configured');
    buffer.writeln('  static Router createRouter({');

    // Handler parameters
    for (final path in apiDoc.paths) {
      for (final op in path.operations) {
        final handlerName = _camelCase(op.operationId);
        final handlerType = '${_capitalize(op.operationId)}Handler';
        buffer.writeln('    $handlerType? $handlerName,');
      }
    }

    buffer.writeln('  }) {');
    buffer.writeln('    final router = Router();');
    buffer.writeln();

    // Register all routes
    for (final path in apiDoc.paths) {
      for (final op in path.operations) {
        final handlerName = _camelCase(op.operationId);
        final method = op.method.toLowerCase();
        final arrowPath = path.path; // Already in {param} format

        buffer.writeln("    if ($handlerName != null) {");
        buffer.writeln("      router.$method('$arrowPath', $handlerName);");
        buffer.writeln('    }');
      }
    }

    buffer.writeln();
    buffer.writeln('    return router;');
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  void _writeHandlerStubs(StringBuffer buffer) {
    buffer.writeln('// ========== Handler Stubs ==========');
    buffer.writeln('// Implement these handlers in your code');
    buffer.writeln();

    for (final path in apiDoc.paths) {
      for (final op in path.operations) {
        final handlerName = _camelCase(op.operationId);

        buffer.writeln('/// ${op.method} ${path.path}');
        if (op.summary != null) {
          buffer.writeln('/// ${op.summary}');
        }
        if (op.description != null) {
          buffer.writeln('///');
          for (final line in op.description!.split('\n')) {
            buffer.writeln('/// $line');
          }
        }

        // Parameter documentation
        if (op.parameters.isNotEmpty) {
          buffer.writeln('///');
          buffer.writeln('/// Parameters:');
          for (final param in op.parameters) {
            buffer.writeln('/// - ${param.name} (${param.location}): ${param.description ?? ""}');
          }
        }

        buffer.writeln('Future<Response> $handlerName(Request req) async {');

        // Extract parameters
        for (final param in op.parameters) {
          if (param.location == 'path') {
            buffer.writeln("  final ${param.name} = req.params.get('${param.name}');");
          } else if (param.location == 'query') {
            buffer.writeln("  final ${param.name} = req.uri.queryParameters['${param.name}'];");
          }
        }

        buffer.writeln('  // TODO: Implement ${op.operationId}');
        buffer.writeln("  return req.respond.serverError(msg: 'Not implemented');");
        buffer.writeln('}');
        buffer.writeln();
      }
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _camelCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toLowerCase() + s.substring(1);
  }
}
