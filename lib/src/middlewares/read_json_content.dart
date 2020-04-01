import 'dart:async';
import 'dart:convert' show utf8;

import 'package:arrow/src/request.dart';
import 'package:arrow/src/content.dart';

Future<Request> readJsonContent(Request req) async {
  String content = await utf8.decodeStream(req.innerRequest);
  if ((req.method == 'POST' || req.method == 'PUT') &&
      (content == null || content == '')) {
    var res = req.respond();
    res.manager.errorMessages
        .add('[readJsonContent] ${req.method} had no content body.');
    res.send.badRequest();
    return req;
  } else {
    try {
      req.content = JsonContent(content);
    } on FormatException catch (_) {
      var res = req.respond();
      res.manager.errorMessages.add(
          '[readJsonContent] Could not decode bad json format in request.');
      res.send.badRequest(errors: {'msg': 'Bad json formatting.'});
    } catch (e) {
      var res = req.respond();
      res.manager.errorMessages.add('[readJsonContent] $e');
      res.send.badRequest(errors: {'msg': 'Problem reading json.'});
    } finally {
      return req;
    }
  }
}
