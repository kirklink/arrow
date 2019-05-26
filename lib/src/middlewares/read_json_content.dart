import 'dart:async';
import 'dart:convert' show utf8, json;

import 'package:arrow/src/request.dart';
import 'package:arrow/src/content.dart';

Future<Request> readJsonContent(Request req) async {
  String content = await req.innerRequest.transform(utf8.decoder).join();
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
    } on FormatException catch (e) {
      var res = req.respond();
      res.manager.errorMessages.add(
          '[readJsonContent] Could not decode bad json format in request.');
      res.send.badRequest(message: 'Bad json formatting.');
    } catch (e) {
      var res = req.respond();
      res.manager.errorMessages.add('[readJsonContent] $e');
      res.send.badRequest(message: 'Problem reading json.');
    } finally {
      return req;
    }
  }
}
