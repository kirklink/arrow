import 'package:arrow/src/message.dart';
import 'package:arrow/src/responder.dart';
import 'package:arrow/src/request.dart';

class Response extends Message {
  Responder _responder;

  Response(Request req)
      : super(req.innerRequest, req.messenger, req.context, req.alive) {
    _responder = Responder(this);
  }

  

  Responder get send => _responder;

  int get statusCode => _responder.statusCode;

  Future complete() async {
    await _responder.complete();
  }




}
