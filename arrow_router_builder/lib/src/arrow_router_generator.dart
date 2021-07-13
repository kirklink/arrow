import 'dart:convert' show json;

import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/constants/reader.dart';
import 'package:analyzer/dart/element/type.dart';

import 'package:arrow/annotations.dart';

import 'arrow_router_exception.dart';

class ArrowRouterGenerator extends GeneratorForAnnotation<Router> {
  final _checkForRoute = const TypeChecker.fromRuntime(Route);

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    print('running router generator');
    if (element is! ClassElement) {
      throw ('ArrowRouter must only annotate a class.');
    }

    final result = StringBuffer();

    result.writeln(
        'RouterBuilder buildRouter({Pipeline? notFoundPipeline, bool shouldRecover = true, Recoverer? recoverer}) {');
    result.writeln('final c = ${element.displayName}();');

    result.writeln('final r = [');

    // RouteBuilder('GET', 'test', s.getTest)

    final routes = StringBuffer();

    for (final field in element.fields) {
      if (field.isStatic || field.isSynthetic) {
        continue;
      }

      print(field.displayName);

      if (_checkForRoute.hasAnnotationOfExact(field)) {
        print('FOUND ROUTE');
        final reader = ConstantReader(_checkForRoute.firstAnnotationOf(field));
        final method = reader.peek('method')!.stringValue;
        final path = reader.peek('path')!.stringValue;
        routes
            .write("RouteBuilder('$method', '$path', c.${field.displayName}),");
        // print("RouteBuilder('$method', '$path', c.${field.displayName}),");
      }
    }

    result.writeln(routes);
    result.writeln("];");
    // result.writeln("final r = [RouteBuilder('GET', 'test', s.getTest)];");
    result.writeln(
        'return RouterBuilder(r, notFoundPipeline: notFoundPipeline, shouldRecover: shouldRecover, recoverer: recoverer);');

    result.writeln('}');

    // final DartType? requestModel = annotation.peek('requestModel')?.typeValue;
    // final DartType? responseModel = annotation.peek('responseModel')?.typeValue;

    // if (requestModel == null) {
    //   throw ArrowOpenapiBuilderException('The provided model is null.');
    // }

    // final name = requestModel.getDisplayString(withNullability: false);
    // if (models.containsKey(name))
    // for (final f in (requestModel.element as ClassElement).fields) {
    //   print(f.displayName);
    //   print(f.type);
    // }

    // for (final field in element.fields) {
    //   print(field.getter);
    // }

    return result.toString();
  }
}
