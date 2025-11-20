import 'dart:async';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';

import 'mcp_server_builder.dart';

/// Generator that creates MCP servers from Arrow service classes
class McpServerGenerator extends Generator {
  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) async {
    // Find all classes with @Router and @McpServer annotations
    final mcpClasses = <ClassElement>[];

    for (final element in library.allElements) {
      if (element is ClassElement) {
        var hasRouter = false;
        var hasMcpServer = false;

        for (final meta in element.metadata) {
          try {
            final value = meta.computeConstantValue();
            final typeName = value?.type?.getDisplayString(withNullability: false);

            if (typeName == 'Router') hasRouter = true;
            if (typeName == 'McpServer') hasMcpServer = true;
          } catch (e) {
            continue;
          }
        }

        // Need both annotations to generate MCP server
        if (hasRouter && hasMcpServer) {
          mcpClasses.add(element);
        }
      }
    }

    if (mcpClasses.isEmpty) {
      return null; // No MCP server classes found
    }

    // Build MCP server code
    final builder = McpServerBuilder();

    for (final mcpClass in mcpClasses) {
      // Extract @McpServer annotation
      String serverName = 'api_server';
      String? serverDescription;

      for (final meta in mcpClass.metadata) {
        try {
          final value = meta.computeConstantValue();
          final typeName = value?.type?.getDisplayString(withNullability: false);

          if (typeName == 'McpServer') {
            serverName = value?.getField('name')?.toStringValue() ?? serverName;
            serverDescription = value?.getField('description')?.toStringValue();
          }
        } catch (e) {
          continue;
        }
      }

      builder.setServerInfo(serverName, serverDescription);

      // Extract API base URL from @OpenApiService
      for (final meta in mcpClass.metadata) {
        try {
          final value = meta.computeConstantValue();
          final typeName = value?.type?.getDisplayString(withNullability: false);

          if (typeName == 'OpenApiService') {
            final backend = value?.getField('backend')?.toStringValue() ?? '';
            if (backend.isNotEmpty) {
              builder.setBaseUrl(backend);
            }
          }
        } catch (e) {
          continue;
        }
      }

      // Extract routes with @Route and @McpTool annotations
      for (final field in mcpClass.fields) {
        String? method;
        String? path;
        String? toolDescription;
        Map<String, String>? parameters;

        for (final meta in field.metadata) {
          try {
            final value = meta.computeConstantValue();
            final typeName = value?.type?.getDisplayString(withNullability: false);

            if (typeName == 'Route') {
              method = value?.getField('method')?.toStringValue();
              path = value?.getField('path')?.toStringValue();
            } else if (typeName == 'McpTool') {
              toolDescription = value?.getField('description')?.toStringValue();
              // TODO: Extract parameters map from annotation
            }
          } catch (e) {
            continue;
          }
        }

        // Add tool if we have route information
        if (method != null && path != null) {
          builder.addTool(
            name: field.name,
            method: method,
            path: path,
            description: toolDescription ?? 'Call ${field.name}',
            parameters: parameters,
          );
        }
      }
    }

    // Generate the MCP server code
    return builder.build();
  }
}

/// Builder function for build.yaml
Builder mcpServerBuilder(BuilderOptions options) {
  return LibraryBuilder(
    McpServerGenerator(),
    generatedExtension: '.mcp.dart',
  );
}
