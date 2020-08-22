import 'dart:convert' show jsonEncode;
import 'package:http/http.dart' as http;


abstract class ArrowRequest {

  static const _sendHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  };

  static const _acceptHeaders = {
    'Accept': 'application/json'
  };

  static Map<String, String> _addAuthToken(Map<String, String> headers, String token) {
    if (token.isNotEmpty) {
      return headers..addAll({'Authorization': 'Bearer $token'});
    } else {
      return headers;
    }
  }

  static Future<http.Response> get(Uri uri, {String token = ''}) {
    final headers = _addAuthToken(_acceptHeaders, token);
    return http.get(uri, headers: headers);
  }

  static Future<http.Response> post(Uri uri, {Map<String, Object> body = const <String, Object>{}, String token = ''}) async {
    final headers = _addAuthToken(_sendHeaders, token);
    return await http.post(uri, body: jsonEncode(body), headers: headers);
  }

  static Future<http.Response> put(Uri uri, {Map<String, Object> body = const <String, Object>{}, String token = ''}) {
    final headers = _addAuthToken(_sendHeaders, token);
    return http.put(uri, body: jsonEncode(body), headers: headers);
  }

  static Future<http.Response> patch(Uri uri, {Map<String, Object> body = const <String, Object>{}, String token = ''}) {
    final headers = _addAuthToken(_sendHeaders, token);
    return http.patch(uri, body: jsonEncode(body), headers: headers);
  }

  static Future<http.Response> delete(Uri uri, {String token = ''}) {
    final headers = _addAuthToken(_acceptHeaders, token);
    return http.delete(uri, headers: headers);
  }

}