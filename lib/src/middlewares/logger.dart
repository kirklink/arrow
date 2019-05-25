import 'package:arrow/src/request.dart';
import 'package:arrow/src/response.dart';
import 'package:arrow/src/request_middleware.dart';
import 'package:arrow/src/response_middleware.dart';
import 'package:arrow/src/context.dart';

/// A function type that takes a String message and handles logging the message.
typedef void Logger(String msg);

final loggerContextKey = Context.makeKey();

class LogRequests {
  DateTime _startTime = DateTime.now().toUtc();
  DateTime _endTime;
  String _method;
  String _path;

  LogRequests(Request request) {
    _method = request.method;
    _path = request.uri.path;
  }

  void end() {
    _endTime = DateTime.now().toUtc();
  }

  String message() {
    String message =
        "$_method $_path ${_startTime} ${_endTime} ${_endTime.difference(_startTime).inMilliseconds}ms";
    return message;
  }
}

RequestMiddleware loggerIn() {
  return (Request req) {
    req.context.set(loggerContextKey, LogRequests(req));
    return req;
  };
}

String _messages(Response res, bool isOn) {
  if (res.manager.messages.list.length > 0 && isOn) {
    return '\nMessages: ${res.manager.messages.string}';
  } else {
    return '';
  }
}

String _errorMessages(Response res, bool isOn) {
  if (res.manager.errorMessages.list.length > 0 && isOn) {
    return '\nError messages: ${res.manager.errorMessages.string}';
  } else {
    return '';
  }
}

ResponseMiddleware loggerOut({Logger logger: null, bool messages: false}) {
  return (Response res) {
    if (logger == null) logger = _defaultLogger;
    var log = res.context.get<LogRequests>(loggerContextKey);
    log.end();
    if (res.statusCode < 200 || res.statusCode > 299) {
      logger(
          '[ERROR] ${res.statusCode.toString()} ${log.message()}${_messages(res, messages)}${_errorMessages(res, messages)}');
    } else {
      logger(
          '${res.statusCode.toString()} ${log.message()}${_messages(res, messages)}');
    }
    return res;
  };
}

void _defaultLogger(String msg) {
  print(msg);
}
