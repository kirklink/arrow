import 'dart:async' show FutureOr;

import 'package:arrow/src/response.dart';

typedef FutureOr<Response> ResponseMiddleware(Response res);
