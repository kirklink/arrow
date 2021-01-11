import 'dart:async';
import 'dart:convert' show utf8, json;

import 'package:arrow/src/request.dart';
import 'package:arrow/src/content.dart';

class JsonContent implements Content {
  Map<String, Object> _content;

  JsonContent(String content) {
    if (content.trim().isEmpty) {
      _content = const {};
    } else {
      final c = json.decode(content);
      if (c is Map) {
        _content = c;
      } else if (c is List) {
        _content = {'data': c};
      } else {
        throw FormatException('Body is not an object or list.');
      }
    }
  }

  String get string => json.encode(_content);

  Map<String, Object> get map => _content;
}

Future<Request> readJsonContent(Request req) async {
  String content = await utf8.decoder.bind(req.innerRequest).join();
  if ((req.method == 'POST' || req.method == 'PUT' || req.method == 'PATCH') &&
      (content == null || content == '')) {
    var res = req.response;
    req.messenger
        .addError('[readJsonContent] ${req.method} had no content body.');
    res.send.badRequest(msg: '${req.method} had no content.');
    return req;
  } else if ((req.method == 'GET' || req.method == 'DELETE') &&
      content.isNotEmpty) {
    final res = req.response;
    req.messenger.addError(
        'readJsonContent ${req.method} should not have content in the body.');
    res.send.badRequest(msg: '${req.method} should not have a body.');
    return req;
  } else {
    try {
      req.content = JsonContent(content != null ? content : '');
    } on FormatException catch (_) {
      var res = req.response;
      res.messenger.addError(
          '[readJsonContent] Could not decode bad json format in request.');
      res.send.badRequest(errors: {'msg': 'Bad json formatting.'});
    } catch (e) {
      var res = req.response;
      res.messenger.addError('[readJsonContent] $e');
      res.send.badRequest(errors: {'msg': 'Problem reading json.'});
    } finally {
      return req;
    }
  }
}
