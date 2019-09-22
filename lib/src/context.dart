import 'package:bottom_line/uuid4.dart';
import 'package:bottom_line/locker.dart';

class Context<T> extends Locker<T> {
  static makeKey() {
    return Uuid4();
  }
}
