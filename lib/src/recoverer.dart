import 'dart:async';

import 'request.dart';
import 'response.dart';

typedef Future<Response> Recoverer(Request req,
    {Exception exception, StackTrace stacktrace, Error error});
