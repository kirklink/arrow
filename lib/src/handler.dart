import 'dart:async' show FutureOr;

import 'request.dart';
import 'response.dart';

/// The function that executes the main logic for an endpoint. A [Handler] takes
/// a [Request] and returns a [Response] with a data payload or relevant
/// errors.
typedef FutureOr<Response> Handler(Request req);
