import 'dart:async' show FutureOr;

import 'response.dart';

typedef FutureOr<Response> ResponseMiddleware(Response res);
