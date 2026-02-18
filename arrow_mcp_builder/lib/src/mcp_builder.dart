import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'mcp_generator.dart';

/// Builder factory function referenced by build.yaml.
Builder mcpBuilder(BuilderOptions options) =>
    LibraryBuilder(McpServerGenerator(), generatedExtension: '.mcp.dart');
