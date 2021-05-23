import 'dart:convert' show json;

import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/constants/reader.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:pretty_json/pretty_json.dart' as pj;

import 'annotations.dart';
import 'arrow_openapi_exception.dart';

final _checkForOpenApiRoute = const TypeChecker.fromRuntime(OpenApiRoute);
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

    for (final f in element.fields) {
      if (_checkForOpenApiRoute.hasAnnotationOfExact(f)) {
        final routeReader =
            ConstantReader(_checkForOpenApiRoute.firstAnnotationOf(f));
        final reqModelType =
            routeReader.peek('requestModel')!.objectValue;
        print(reqModelType!.getDisplayString(withNullability: false));

        // final reqModelElementName = reqModelElement.displayName;
        // print(reqModelElementName);
        // if (reqModelElement is! ClassElement) {
        //   throw ArrowOpenapiBuilderException(
        //       'The Open API model $reqModelElementName must be a class element.');
        // }
        // print(_checkForOpenApiModel.hasAnnotationOf(reqModelElement.kind.));
        // print(_checkForOpenApiModel.hasAnnotationOfExact(reqModelElement));
        // if (!_checkForOpenApiModel.hasAnnotationOfExact(reqModelElement)) {
        //   throw ArrowOpenapiBuilderException(
        //       '$reqModelElementName must be annotated with @OpenApiModel.');
        // }
        // final reqModelReader = ConstantReader(
        //     _checkForOpenApiModel.firstAnnotationOf(reqModelElement));
        // for (final field in reqModelElement.fields) {
        //   print(field.displayName);
        // }

        // print('requestModel');
        // print(reqModelType.getDisplayString(withNullability: false));
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
    return pj.prettyJson(header);
  }
}
