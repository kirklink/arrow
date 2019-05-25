typedef T Creator<T>(Map<String, Object> map);

abstract class ToJson {
  Map<String, Object> toJson();
}
