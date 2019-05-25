import 'package:arrow/src/message.dart';
import 'package:arrow/src/responder.dart';
import 'package:arrow/src/request.dart';

class Response extends Message {
  Responder _responder;

  Response(Request req, {String wrapper, bool wrapped})
      : super(req.innerRequest, manager: req.manager, context: req.context) {
    _responder =
        Responder(innerRequest, manager, wrapper: wrapper, isWrapped: wrapped);
  }

  Responder get send => _responder;

  int get statusCode => innerRequest.response.statusCode;

  bool get isSuccess {
    if (innerRequest.response.statusCode == null) return null;
    return innerRequest.response.statusCode >= 200 &&
        innerRequest.response.statusCode < 300;
  }
}
