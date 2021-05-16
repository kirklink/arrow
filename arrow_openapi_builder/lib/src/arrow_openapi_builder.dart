import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'arrow_openapi_generator.dart';

Builder ArrowOpenApiBuilder(BuilderOptions options) =>
    LibraryBuilder(ArrowOpenApiGenerator(),
        generatedExtension: '.json', header: '');
