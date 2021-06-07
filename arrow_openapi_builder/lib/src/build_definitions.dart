import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/constants/reader.dart';
import 'package:analyzer/dart/element/type.dart';

class OpenApiDefinition {
  final String type;
  final String name;
  final _properties = <OpenApiProperty>[];

  OpenApiDefinition(this.name, {this.type = 'object'});

  void addProperty(OpenApiProperty property) {
    _properties.add(property);
  }

  Map<String, dynamic> toJson() {
    final r = <String, dynamic>{};
    r['type'] = type;
    if (_properties.isNotEmpty) {
      r['properties'] = _properties.map((e) => e.toJson()).toList();
    }
    return r;
  }
}

class OpenApiProperty {
  final String name;
  final String type;
  final String format;
  final String description;

  OpenApiProperty(this.name, this.type,
      {this.format = '', this.description = ''});

  Map<String, dynamic> toJson() {
    final r = <String, dynamic>{};
    final d = <String, String>{};
    d['type'] = type;
    if (format.isNotEmpty) d['format'] = format;
    if (description.isNotEmpty) d['description'] = description;
    r[name] = d;
    return r;
  }
}

Map<String, dynamic> buildDefinitions(
    Map<String, DartType> reqModels, Map<String, DartType> resModels) {
  reqModels.entries.forEach((MapEntry<String, DartType> entry) {
    var name = entry.key;
    if (resModels.containsKey(name)) name = name + '_req';
    final definition = modelToDefinition(name, entry.value);
  });

  return const {};
}

OpenApiDefinition modelToDefinition(String name, DartType model) {
  final definition = OpenApiDefinition(name);
  (model.element as ClassElement).fields.forEach((field) {
    // Read the field annotations
    // print(field.displayName);
    var type = '';
    var format = '';
    if (field.type.isDartCoreString) {
      type = 'string';
    }
    final property = OpenApiProperty(field.displayName, type, format: format);
    definition.addProperty(property);
  });

  return definition;
}
