import 'package:arrow/src/request.dart';
import 'package:arrow/src/request_middleware.dart';

RequestMiddleware withValue<T>({String key, T value}) {
  return (Request req) async {
    if (key == null || value == null) return req;
    req.context.set(key, value);
    return req;
  };
}
