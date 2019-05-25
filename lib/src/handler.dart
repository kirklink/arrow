import 'dart:async' show FutureOr;

import 'package:arrow/src/request.dart';
import 'package:arrow/src/response.dart';

typedef FutureOr<Response> Handler(Request req);
