import 'dart:convert' show json;

import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/constants/reader.dart';
import 'package:analyzer/dart/element/type.dart';

import 'annotations.dart';
import 'arrow_openapi_exception.dart';

final _checkForOpenApiRoute = const TypeChecker.fromRuntime(OpenApiRoute);

class OpenApiModelProperty {
  final String name;
  final String type;
  final String format;
  final bool required;
  const OpenApiModelProperty(this.name, this.type,
      {this.format = '', this.required = false});

  Map<String, dynamic> toJson() {
    final r = {
      name: {'type': type}
    };
    if (format.isNotEmpty) r[name]!.addAll({'format': format});
    return r;
  }
}

class OpenApiModel {
  final type = 'object';
  final _properties = <OpenApiModelProperty>[];

  Map<String, dynamic> toJson() {
    final r = <String, dynamic>{'type': type};
    if (_properties.isNotEmpty) {
      r['properties'] = _properties.map((e) => e.toString()).toList();
    }
    return r;
  }

  void addProperty(OpenApiModelProperty property) {
    _properties.add(property);
  }
}

final models = <String, StringBuffer>{};

class ArrowOpenApiGenerator extends GeneratorForAnnotation<OpenApiRouter> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    print('running openapi generator');
    if (element is! ClassElement) {
      throw ('OpenApiRouter must only annotate a class.');
    }
    for (final f in element.fields) {
      if (_checkForOpenApiRoute.hasAnnotationOfExact(f)) {
        print('FOUND OPENAPI ROUTE');
      }
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
    return json.encode({'test': 'test'});
  }
}
