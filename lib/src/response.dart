import 'package:arrow/src/message.dart';
import 'package:arrow/src/responder.dart';
import 'package:arrow/src/request.dart';
import 'package:arrow/src/global.dart';

class Response extends Message {
  Responder _responder;
  Global _global = Global();

  Response(Request req, {String wrapper, bool wrapped})
      : super(req.innerRequest, manager: req.manager, context: req.context) {
    _responder =
        Responder(innerRequest, manager, wrapper: wrapper, isWrapped: wrapped);
  }

  Global get global => _global;

  Map<String, Object> get env => _global.variables.get('ENV');

  bool get isOnProd => env['ARROW_ENVIRONMENT'] == 'production';

  Responder get send => _responder;

  int get statusCode => innerRequest.response.statusCode;

  bool get isSuccess {
    if (innerRequest.response.statusCode == null) return null;
    return innerRequest.response.statusCode >= 200 &&
        innerRequest.response.statusCode < 300;
  }
}
