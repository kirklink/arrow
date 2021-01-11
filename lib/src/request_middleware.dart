import 'dart:async' show FutureOr;

import 'request.dart';

typedef FutureOr<Request> RequestMiddleware(Request req);
