import 'package:arrow/src/locker.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';


// TODO: Combine this with locker.dart

class Context<T> extends Locker<T> {
  static String makeKey() {
    final uuid = Uuid(options: {
      'gnrg' : UuidUtil.cryptoRNG()
    }).v4();
    return uuid;
  }
}
