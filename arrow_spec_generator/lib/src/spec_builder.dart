
/// Builds OpenAPI 3.0 specifications from route information
class OpenApiSpecBuilder {
  String _title = 'API';
  String _version = '1.0.0';
  String? _description;
  String _server = 'http://localhost:8080';

  final Map<String, Map<String, dynamic>> _paths = {};
  final Map<String, dynamic> _schemas = {};

  /// Set API info metadata
  void setInfo(String title, String version, {String? description}) {
    _title = title;
    _version = version;
    _description = description;
  }

  /// Set server URL
  void setServer(String server) {
    // Add protocol if missing
    if (!server.startsWith('http://') && !server.startsWith('https://')) {
      server = 'https://$server';
    }
    _server = server;
  }

  /// Add a route to the specification
  void addRoute({
    required String method,
    required String path,
    required String operationId,
    String? summary,
    String? description,
    Map<String, dynamic>? requestBody,
    Map<String, dynamic>? response,
  }) {
    // Normalize path to OpenAPI format (already uses {param})
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    // Initialize path if it doesn't exist
    if (!_paths.containsKey(normalizedPath)) {
      _paths[normalizedPath] = {};
    }

    // Add operation
    _paths[normalizedPath]![method.toLowerCase()] = {
      'operationId': operationId,
      if (summary != null) 'summary': summary,
      if (description != null) 'description': description,
      'responses': {
        '200': {
          'description': 'Successful response',
          'content': {
            'application/json': {
              'schema': {
                'type': 'object',
              }
            }
          }
        }
      },
      if (requestBody != null) 'requestBody': requestBody,
    };
  }

  /// Add a schema definition
  void addSchema(String name, Map<String, dynamic> schema) {
    _schemas[name] = schema;
  }

  /// Build the OpenAPI spec as a Map
  Map<String, dynamic> build() {
    return {
      'openapi': '3.0.0',
      'info': {
        'title': _title,
        'version': _version,
        if (_description != null) 'description': _description,
      },
      'servers': [
        {'url': _server}
      ],
      'paths': _paths,
      if (_schemas.isNotEmpty)
        'components': {
          'schemas': _schemas,
        },
    };
  }

  /// Build the OpenAPI spec as YAML string
  String buildYaml() {
    final spec = build();
    return _toYaml(spec, 0);
  }

  /// Convert a Map to YAML string with proper indentation
  String _toYaml(dynamic value, int indent) {
    final buffer = StringBuffer();
    final spaces = '  ' * indent;

    if (value is Map) {
      value.forEach((key, val) {
        if (val is Map) {
          buffer.writeln('$spaces$key:');
          buffer.write(_toYaml(val, indent + 1));
        } else if (val is List) {
          buffer.writeln('$spaces$key:');
          buffer.write(_toYaml(val, indent + 1));
        } else {
          buffer.writeln('$spaces$key: ${_yamlValue(val)}');
        }
      });
    } else if (value is List) {
      for (final item in value) {
        if (item is Map) {
          buffer.writeln('$spaces-');
          item.forEach((key, val) {
            if (val is Map || val is List) {
              buffer.writeln('$spaces  $key:');
              buffer.write(_toYaml(val, indent + 2));
            } else {
              buffer.writeln('$spaces  $key: ${_yamlValue(val)}');
            }
          });
        } else {
          buffer.writeln('$spaces- ${_yamlValue(item)}');
        }
      }
    }

    return buffer.toString();
  }

  /// Format a value for YAML
  String _yamlValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) {
      // Quote strings if they contain special characters
      if (value.contains(':') || value.contains('#') || value.contains('\n')) {
        return "'${value.replaceAll("'", "''")}'";
      }
      return value;
    }
    return value.toString();
  }
}
