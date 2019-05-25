import 'dart:async' show FutureOr;

import 'package:arrow/src/request.dart';

typedef FutureOr<Request> RequestMiddleware(Request req);
