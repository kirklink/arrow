import 'dart:convert' show json;

import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/constants/reader.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:pretty_json/pretty_json.dart' as pj;

import 'package:arrow/annotations.dart';

import 'arrow_openapi_exception.dart';
import 'build_definitions.dart';

final _checkForOpenApiRoute = const TypeChecker.fromRuntime(Route);
final _checkForOpenApiModel = const TypeChecker.fromRuntime(OpenApiModel);
final _checkForOpenApiField = const TypeChecker.fromRuntime(OpenApiField);

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

// class OpenApiModel {
//   final type = 'object';
//   final _properties = <OpenApiModelProperty>[];

//   Map<String, dynamic> toJson() {
//     final r = <String, dynamic>{'type': type};
//     if (_properties.isNotEmpty) {
//       r['properties'] = _properties.map((e) => e.toString()).toList();
//     }
//     return r;
//   }

//   void addProperty(OpenApiModelProperty property) {
//     _properties.add(property);
//   }
// }

final models = <String, StringBuffer>{};

// class ArrowOpenApiGenerator extends Generator {
//   @override
//   String generate(LibraryReader library, _) {
//     for (final classElement in library.allElements.whereType<ClassElement>()) {
//       print(classElement.displayName);
//     }
//     return "const test = 'OPEN API GENERATE';";
//   }
// }

class ArrowOpenApiGenerator extends GeneratorForAnnotation<OpenApiRouter> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    print('running openapi generator');
    if (element is! ClassElement) {
      throw ('OpenApiRouter must only annotate a class.');
    }

    const specVersion = "2.0";
    final title = annotation.peek('title')!.stringValue;
    final description = annotation.peek('description')!.stringValue;
    final termsOfService = annotation.peek('termsOfService')!.stringValue;
    final apiVersion = annotation.peek('version')!.stringValue;
    final contact = annotation.peek('contact')!.objectValue;
    final license = annotation.peek('license')!.objectValue;

    final contactName = contact.getField('name')!.toStringValue()!;
    final contactUrl = contact.getField('url')!.toStringValue()!;
    final contactEmail = contact.getField('email')!.toStringValue()!;

    final licenseName = license.getField('name')!.toStringValue()!;
    final licenseUrl = license.getField('url')!.toStringValue()!;

    final header = <String, dynamic>{'swagger': specVersion, 'title': title};
    if (description.isNotEmpty) header['description'] = description;
    if (termsOfService.isNotEmpty) header['termsOfService'] = termsOfService;

    final contactMap = <String, String>{};
    if (contactName.isNotEmpty) contactMap['name'] = contactName;
    if (contactUrl.isNotEmpty) contactMap['url'] = contactUrl;
    if (contactEmail.isNotEmpty) contactMap['emai'] = contactEmail;

    if (contactMap.isNotEmpty) {
      header['contact'] = contactMap;
    }

    final licenseMap = <String, String>{};
    if (licenseName.isNotEmpty) licenseMap['name'] = licenseName;
    if (licenseUrl.isNotEmpty) licenseMap['url'] = licenseUrl;

    if (licenseMap.isNotEmpty) {
      header['license'] = licenseMap;
    }

    header['version'] = apiVersion;

    final reqModels = <String, DartType>{};
    final resModels = <String, DartType>{};

    for (final route in element.fields) {
      if (!_checkForOpenApiRoute.hasAnnotationOfExact(route)) {
        continue;
      }
      // print(route.);
      // print(route.computeConstantValue());

      final routeReader =
          ConstantReader(_checkForOpenApiRoute.firstAnnotationOf(route));
      final reqModelType = routeReader.peek('requestModel')!.typeValue;
      final reqModelName =
          reqModelType.getDisplayString(withNullability: false);
      final resModelType = routeReader.peek('responseModel')!.typeValue;
      final resModelName =
          resModelType.getDisplayString(withNullability: false);
      if (!_checkForOpenApiModel.hasAnnotationOfExact(reqModelType.element!)) {
        throw ArrowOpenapiBuilderException('');
      }
      if (!_checkForOpenApiModel.hasAnnotationOfExact(resModelType.element!)) {
        throw ArrowOpenapiBuilderException('');
      }
      reqModels[reqModelName] = reqModelType;
      resModels[resModelName] = resModelType;
    }

    final x = buildDefinitions(reqModels, resModels);

    return pj.prettyJson(header);
  }
}
