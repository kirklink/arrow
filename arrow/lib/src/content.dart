// Interface definition for processed request content
abstract class Content {
  String get string;
  Map<String, Object> get map;
  List get list;
}
