import 'dart:convert' show json;

import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/constants/reader.dart';
import 'package:analyzer/dart/element/type.dart';

import 'annotations.dart';
import 'arrow_router_exception.dart';

class ArrowRouterGenerator extends GeneratorForAnnotation<ArrowRouter> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    print('running router generator');
    if (element is! ClassElement) {
      throw ('ArrowRouter must only annotate a class.');
    }
    for (final f in element.fields) {
      print(f.displayName);
    }

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
    print(element.displayName);
    return '// DONE - ROUTER';
  }
}
