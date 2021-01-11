import 'getter_setter.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';

class Context<T> extends GetterSetter<T> {
  static String makeKey() {
    final uuid = Uuid(options: {'gnrg': UuidUtil.cryptoRNG()}).v4();
    return uuid;
  }
}
