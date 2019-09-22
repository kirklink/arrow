import 'package:bottom_line/uuid4.dart';
import 'package:bottom_line/getter_setter.dart';

class Context<T> extends GetterSetter<T> {
  static makeKey() {
    return Uuid4();
  }
}
