import 'package:arrow/src/request.dart';
import 'package:arrow/src/response.dart';
import 'package:arrow/src/request_middleware.dart';
import 'package:arrow/src/response_middleware.dart';
import 'package:arrow/src/context.dart';

/// A function type that takes a String message and handles logging the message.
typedef void Logger(String msg);

final loggerContextKey = Context.makeKey();

// A class that logs HTTP requests.
///
/// This class is responsible for tracking and recording all incoming and outgoing requests.
/// It can be useful for debugging and monitoring purposes.
class LogRequests {
  final DateTime _startTime = DateTime.now().toUtc();
  late final DateTime _endTime;
  late final String _method;
  late final String _path;

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
  return (Request req) async {
    req.context.trySet(loggerContextKey, LogRequests(req));
    return req;
  };
}

String _messages(Response res, bool isOn) {
  if (res.messenger.messages.length > 0 && isOn) {
    return '\nMessages: ${res.messenger.messages.join(' | ')}';
  } else {
    return '';
  }
}

String _errorMessages(Response res, bool isOn) {
  if (res.messenger.errors.length > 0 && isOn) {
    return '\nError messages: ${res.messenger.errors.join(' | ')}';
  } else {
    return '';
  }
}

ResponseMiddleware loggerOut(
    {Logger? logger = _defaultLogger, bool messages = false}) {
  return (Response? res) async {
    final log = res!.context.tryGet<LogRequests>(loggerContextKey)!;
    log.end();
    if (res.statusCode < 200 || res.statusCode > 299) {
      logger!(
          '[ERROR] ${res.statusCode} ${log.message()}${_messages(res, messages)}${_errorMessages(res, messages)}');
    } else {
      logger!('${res.statusCode} ${log.message()}${_messages(res, messages)}');
    }
    return res;
  };
}

void _defaultLogger(String msg) {
  print(msg);
}
