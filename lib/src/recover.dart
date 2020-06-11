import 'dart:async';

import 'package:arrow/src/request.dart';
import 'package:arrow/src/response.dart';

typedef FutureOr<Response> Recoverer(Request req, {Exception exception, StackTrace stacktrace, Error error});
