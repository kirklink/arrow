/// Parser for OpenAPI 3.0 specifications

/// Represents a parsed OpenAPI document
class ApiDocument {
  final String version;
  final ApiInfo info;
  final List<ApiPath> paths;
  final Map<String, ApiSchema> schemas;

  ApiDocument({
    required this.version,
    required this.info,
    required this.paths,
    required this.schemas,
  });
}

/// API metadata
class ApiInfo {
  final String title;
  final String version;
  final String? description;

  ApiInfo({
    required this.title,
    required this.version,
    this.description,
  });
}

/// Represents a path in the API
class ApiPath {
  final String path;
  final List<ApiOperation> operations;

  ApiPath({
    required this.path,
    required this.operations,
  });
}

/// Represents an HTTP operation (GET, POST, etc.)
class ApiOperation {
  final String method;
  final String operationId;
  final String? summary;
  final String? description;
  final List<ApiParameter> parameters;
  final ApiRequestBody? requestBody;
  final Map<int, ApiResponse> responses;
  final List<String> tags;

  ApiOperation({
    required this.method,
    required this.operationId,
    this.summary,
    this.description,
    required this.parameters,
    this.requestBody,
    required this.responses,
    required this.tags,
  });

  /// Convert path parameters from OpenAPI format to Arrow format
  /// e.g., /users/{userId} stays as /users/{userId} (Arrow uses RFC 6570)
  String get arrowPath => path;

  String get path => _path;
  set path(String value) => _path = value;
  String _path = '';
}

/// Represents a parameter (path, query, header, etc.)
class ApiParameter {
  final String name;
  final String location; // 'path', 'query', 'header', 'cookie'
  final String? description;
  final bool required;
  final ApiSchema? schema;

  ApiParameter({
    required this.name,
    required this.location,
    this.description,
    required this.required,
    this.schema,
  });
}

/// Represents a request body
class ApiRequestBody {
  final String? description;
  final bool required;
  final Map<String, ApiMediaType> content;

  ApiRequestBody({
    this.description,
    required this.required,
    required this.content,
  });
}

/// Represents a media type (e.g., application/json)
class ApiMediaType {
  final ApiSchema? schema;

  ApiMediaType({this.schema});
}

/// Represents a response
class ApiResponse {
  final String description;
  final Map<String, ApiMediaType>? content;

  ApiResponse({
    required this.description,
    this.content,
  });
}

/// Represents a schema (data model)
class ApiSchema {
  final String? type;
  final String? format;
  final String? ref; // $ref reference
  final Map<String, ApiSchema>? properties;
  final List<String>? required;
  final ApiSchema? items; // For arrays
  final List<ApiSchema>? oneOf;
  final List<ApiSchema>? anyOf;
  final List<ApiSchema>? allOf;

  ApiSchema({
    this.type,
    this.format,
    this.ref,
    this.properties,
    this.required,
    this.items,
    this.oneOf,
    this.anyOf,
    this.allOf,
  });

  /// Get the referenced schema name if this is a $ref
  String? get refName {
    if (ref == null) return null;
    final parts = ref!.split('/');
    return parts.last;
  }
}

/// Parser for OpenAPI 3.0 specifications
class OpenApiParser {
  /// Parse an OpenAPI document from a parsed YAML/JSON structure
  ApiDocument parse(dynamic spec) {
    if (spec is! Map) {
      throw ArgumentError('OpenAPI spec must be a map');
    }

    final version = spec['openapi'] as String? ?? '3.0.0';
    final info = _parseInfo(spec['info'] as Map);
    final paths = _parsePaths(spec['paths'] as Map? ?? {});
    final schemas = _parseSchemas(spec['components']?['schemas'] as Map? ?? {});

    return ApiDocument(
      version: version,
      info: info,
      paths: paths,
      schemas: schemas,
    );
  }

  ApiInfo _parseInfo(Map info) {
    return ApiInfo(
      title: info['title'] as String? ?? 'API',
      version: info['version'] as String? ?? '1.0.0',
      description: info['description'] as String?,
    );
  }

  List<ApiPath> _parsePaths(Map paths) {
    final result = <ApiPath>[];

    for (final entry in paths.entries) {
      final path = entry.key as String;
      final pathItem = entry.value as Map;

      final operations = _parseOperations(path, pathItem);
      if (operations.isNotEmpty) {
        result.add(ApiPath(path: path, operations: operations));
      }
    }

    return result;
  }

  List<ApiOperation> _parseOperations(String path, Map pathItem) {
    final operations = <ApiOperation>[];
    final methods = ['get', 'post', 'put', 'delete', 'patch', 'options', 'head'];

    for (final method in methods) {
      if (pathItem.containsKey(method)) {
        final opData = pathItem[method] as Map;
        final operation = _parseOperation(method, path, opData);
        operations.add(operation);
      }
    }

    return operations;
  }

  ApiOperation _parseOperation(String method, String path, Map opData) {
    final operationId = opData['operationId'] as String? ??
        _generateOperationId(method, path);

    final parameters = <ApiParameter>[];
    if (opData['parameters'] != null) {
      for (final param in opData['parameters'] as List) {
        parameters.add(_parseParameter(param as Map));
      }
    }

    final responses = <int, ApiResponse>{};
    if (opData['responses'] != null) {
      for (final entry in (opData['responses'] as Map).entries) {
        final statusCode = int.tryParse(entry.key.toString()) ?? 0;
        responses[statusCode] = _parseResponse(entry.value as Map);
      }
    }

    final operation = ApiOperation(
      method: method.toUpperCase(),
      operationId: operationId,
      summary: opData['summary'] as String?,
      description: opData['description'] as String?,
      parameters: parameters,
      requestBody: opData['requestBody'] != null
          ? _parseRequestBody(opData['requestBody'] as Map)
          : null,
      responses: responses,
      tags: (opData['tags'] as List?)?.cast<String>() ?? [],
    );

    operation.path = path;
    return operation;
  }

  String _generateOperationId(String method, String path) {
    // Convert /users/{id} to getUsersById
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    final methodPart = method.toLowerCase();

    final pathParts = parts.map((part) {
      if (part.startsWith('{') && part.endsWith('}')) {
        final param = part.substring(1, part.length - 1);
        return 'By${_capitalize(param)}';
      }
      return _capitalize(part);
    }).join('');

    return '$methodPart$pathParts';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  ApiParameter _parseParameter(Map param) {
    return ApiParameter(
      name: param['name'] as String,
      location: param['in'] as String,
      description: param['description'] as String?,
      required: param['required'] as bool? ?? false,
      schema: param['schema'] != null ? _parseSchema(param['schema'] as Map) : null,
    );
  }

  ApiRequestBody _parseRequestBody(Map body) {
    final content = <String, ApiMediaType>{};

    if (body['content'] != null) {
      for (final entry in (body['content'] as Map).entries) {
        final mediaType = entry.key as String;
        final mediaTypeData = entry.value as Map;
        content[mediaType] = ApiMediaType(
          schema: mediaTypeData['schema'] != null
              ? _parseSchema(mediaTypeData['schema'] as Map)
              : null,
        );
      }
    }

    return ApiRequestBody(
      description: body['description'] as String?,
      required: body['required'] as bool? ?? false,
      content: content,
    );
  }

  ApiResponse _parseResponse(Map response) {
    final content = <String, ApiMediaType>{};

    if (response['content'] != null) {
      for (final entry in (response['content'] as Map).entries) {
        final mediaType = entry.key as String;
        final mediaTypeData = entry.value as Map;
        content[mediaType] = ApiMediaType(
          schema: mediaTypeData['schema'] != null
              ? _parseSchema(mediaTypeData['schema'] as Map)
              : null,
        );
      }
    }

    return ApiResponse(
      description: response['description'] as String? ?? '',
      content: content.isNotEmpty ? content : null,
    );
  }

  Map<String, ApiSchema> _parseSchemas(Map schemas) {
    final result = <String, ApiSchema>{};

    for (final entry in schemas.entries) {
      final name = entry.key as String;
      result[name] = _parseSchema(entry.value as Map);
    }

    return result;
  }

  ApiSchema _parseSchema(Map schema) {
    final properties = <String, ApiSchema>{};

    if (schema['properties'] != null) {
      for (final entry in (schema['properties'] as Map).entries) {
        properties[entry.key as String] = _parseSchema(entry.value as Map);
      }
    }

    return ApiSchema(
      type: schema['type'] as String?,
      format: schema['format'] as String?,
      ref: schema['\$ref'] as String?,
      properties: properties.isNotEmpty ? properties : null,
      required: (schema['required'] as List?)?.cast<String>(),
      items: schema['items'] != null ? _parseSchema(schema['items'] as Map) : null,
    );
  }
}
