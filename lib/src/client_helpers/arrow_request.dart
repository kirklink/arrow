import 'dart:convert' show jsonEncode;
import 'package:http/http.dart' as http;

abstract class ArrowRequest {
  static final _sendHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  };

  static final _acceptHeaders = {'Accept': 'application/json'};

  static Map<String, String> _addAuthToken(
      Map<String, String> headers, String token) {
    if (token.isNotEmpty) {
      return headers..addAll({'Authorization': 'Bearer $token'});
    } else {
      return headers;
    }
  }

  static Future<http.Response> get(Uri uri,
      {String token = '', http.Client client}) {
    if (client == null) {
      client = http.Client();
    }
    final headers = _addAuthToken(_acceptHeaders, token);
    final res = client.get(uri, headers: headers);
    client.close();
    return res;
  }

  static Future<http.Response> post(Uri uri,
      {Map<String, Object> body = const <String, Object>{},
      String token = '',
      http.Client client}) async {
    if (client == null) {
      client = http.Client();
    }
    final headers = _addAuthToken(_sendHeaders, token);
    final res = client.post(uri, body: jsonEncode(body), headers: headers);
    client.close();
    return res;
  }

  static Future<http.Response> put(Uri uri,
      {Map<String, Object> body = const <String, Object>{},
      String token = '',
      http.Client client}) {
    if (client == null) {
      client = http.Client();
    }
    final headers = _addAuthToken(_sendHeaders, token);
    final res = client.put(uri, body: jsonEncode(body), headers: headers);
    client.close();
    return res;
  }

  static Future<http.Response> patch(Uri uri,
      {Map<String, Object> body = const <String, Object>{},
      String token = '',
      http.Client client}) {
    if (client == null) {
      client = http.Client();
    }
    final headers = _addAuthToken(_sendHeaders, token);
    final res = client.patch(uri, body: jsonEncode(body), headers: headers);
    client.close();
    return res;
  }

  static Future<http.Response> delete(Uri uri,
      {String token = '', http.Client client}) {
    if (client == null) {
      client = http.Client();
    }
    final headers = _addAuthToken(_acceptHeaders, token);
    final res = client.delete(uri, headers: headers);
    client.close();
    return res;
  }
}
