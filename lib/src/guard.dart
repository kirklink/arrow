import 'package:arrow/arrow.dart';

import 'request.dart';

typedef Guard = Future<bool> Function(Request req);
