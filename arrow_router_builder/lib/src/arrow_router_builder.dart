import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'arrow_router_generator.dart';

Builder ArrowRouterBuilder(BuilderOptions options) =>
    SharedPartBuilder([ArrowRouterGenerator()], 'arrow_router_builder');
