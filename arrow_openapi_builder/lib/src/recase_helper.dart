import 'package:recase/recase.dart';

String recaseFieldName(int enumValue, String fieldName) {
  final rc = ReCase('$fieldName');
    switch (enumValue) {
      case 0: return fieldName;
        break;
      case 1: return rc.camelCase;
        break;
      case 2: return rc.snakeCase;
        break;
      case 3: return rc.pascalCase;
        break;
      case 4: return rc.paramCase;
        break;
      default: return fieldName;
      break;
  }
}
