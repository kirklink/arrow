import 'package:bottom_line/bottom_line.dart';

class Context<T> extends GetterSetter<T> {
  static makeKey() {
    return makeUuid4Key();
  }
}
