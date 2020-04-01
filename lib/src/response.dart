import 'dart:io' as io;

import 'package:arrow/src/message.dart';
import 'package:arrow/src/responder.dart';
import 'package:arrow/src/request.dart';

class Response extends Message {
  Responder _responder;

  Response(Request req, {String wrapper, bool wrapped})
      : super(req.innerRequest, manager: req.manager, context: req.context) {
    _responder = Responder(manager, wrapped, wrapper);
  }

  bool get isOnProd => io.Platform.environment['ARROW_ENVIRONMENT'] == 'production';

  Responder get send => _responder;

  int get statusCode => _responder.statusCode;

  // bool get isSuccess {
  //   if (innerRequest.response.statusCode == null) return null;
  //   return innerRequest.response.statusCode >= 200 &&
  //       innerRequest.response.statusCode < 300;
  // }


}
