import 'request.dart';

typedef Future<Request> RequestMiddleware(Request req);
