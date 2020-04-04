import 'package:arrow/src/message.dart';
import 'package:arrow/src/responder.dart';
import 'package:arrow/src/request.dart';

class Response extends Message {
  Responder _responder;

  Response(Request req)
      : super(req.innerRequest, req.isAlive, req.messenger, req.context) {
    _responder = Responder(this);
  }

  

  Responder get send => _responder;

  int get statusCode => _responder.statusCode;




}
