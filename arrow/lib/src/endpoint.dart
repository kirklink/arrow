import 'request.dart';
import 'response.dart';

/// The function that executes the main logic for an endpoint. A [Endpoint] takes
/// a [Request] and returns a [Response] with a data payload or relevant
/// errors.
typedef Future<Response> Endpoint(Request req);
