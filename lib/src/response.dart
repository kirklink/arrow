import 'message.dart';
import 'responder.dart';
import 'request.dart';

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
