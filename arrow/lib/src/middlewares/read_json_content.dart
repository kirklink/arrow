import 'dart:async';
import 'dart:convert' show utf8, json;

import 'package:arrow/src/request_middleware.dart';
import 'package:arrow/src/request.dart';
import 'package:arrow/src/content.dart';

class JsonContent implements Content {
  Map<String, Object> _map = const {};
  List _list = const [];

  JsonContent(String content, {String listWrapper = ''}) {
    if (content.trim().isNotEmpty) {
      final c = json.decode(content);
      if (c is Map) {
        _map = c as Map<String, Object>;
      } else if (c is List) {
        if (listWrapper.isNotEmpty) {
          _map = {listWrapper: c};
        } else {
          _list = c;
        }
      } else {
        throw FormatException('Body is not an object or list.');
      }
    }
  }

  String get string => json.encode(_map);
  List get list => List.unmodifiable(_list);
  Map<String, Object> get map => Map.unmodifiable(_map);
}

RequestMiddleware readJsonContent({String listWrapper = ''}) {
  return (Request req) async {
    return _readJsonContent(req, listWrapper: listWrapper);
  };
}

Future<Request> _readJsonContent(Request req, {String listWrapper = ''}) async {
  String content = await utf8.decoder.bind(req.innerRequest).join();
  if ((req.method == 'POST' || req.method == 'PUT' || req.method == 'PATCH') &&
      (content == null || content == '')) {
    req.messenger
        .addError('[readJsonContent] ${req.method} had no content body.');
    req.respond.badRequest(msg: '${req.method} had no content.');
    return req;
  } else if ((req.method == 'GET' || req.method == 'DELETE') &&
      content.isNotEmpty) {
    req.messenger.addError(
        'readJsonContent ${req.method} should not have content in the body.');
    req.respond.badRequest(msg: '${req.method} should not have a body.');
    return req;
  } else {
    try {
      req.content = JsonContent(content != null ? content : '');
    } on FormatException catch (_) {
      req.messenger.addError(
          '[readJsonContent] Could not decode bad json format in request.');
      req.respond.badRequest(errors: {'msg': 'Bad json formatting.'});
    } catch (e) {
      req.messenger.addError('[readJsonContent] $e');
      req.respond.badRequest(errors: {'msg': 'Problem reading json.'});
    } finally {
      return req;
    }
  }
}
