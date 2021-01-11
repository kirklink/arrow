import 'dart:async' show FutureOr;

import 'request.dart';
import 'response.dart';

typedef FutureOr<Response> Handler(Request req);
