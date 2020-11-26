import 'dart:convert' show jsonEncode;
import 'package:http/http.dart' as http;

class ArrowRequestException implements Exception {
  final String reason;
  const ArrowRequestException(this.reason);
  @override
  String toString() => reason;
}

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
    client ??= http.Client();
    final headers = _addAuthToken(_acceptHeaders, token);
    final res = client.get(uri, headers: headers);
    client.close();
    return res;
  }

  static Future<http.Response> post(Uri uri,
      {Object body = const <String, Object>{},
      String token = '',
      http.Client client}) async {
    if (body is! String && body is! Map<String, Object>) {
      throw ArrowRequestException(
          'Body must be a String or Map<String, Object>');
    }
    body = body is String ? body : jsonEncode(body);
    client ??= http.Client();
    final headers = _addAuthToken(_sendHeaders, token);
    final res = client.post(uri, body: body, headers: headers);
    client.close();
    return res;
  }

  static Future<http.Response> put(Uri uri,
      {Object body = const <String, Object>{},
      String token = '',
      http.Client client}) {
    if (body is! String && body is! Map<String, Object>) {
      throw ArrowRequestException(
          'Body must be a String or Map<String, Object>');
    }
    body = body is String ? body : jsonEncode(body);
    client ??= http.Client();
    final headers = _addAuthToken(_sendHeaders, token);
    final res = client.put(uri, body: body, headers: headers);
    client.close();
    return res;
  }

  static Future<http.Response> patch(Uri uri,
      {Map<String, Object> body = const <String, Object>{},
      String token = '',
      http.Client client}) {
    if (body is! String && body is! Map<String, Object>) {
      throw ArrowRequestException(
          'Body must be a String or Map<String, Object>');
    }
    body = body is String ? body : jsonEncode(body);
    client ??= http.Client();
    final headers = _addAuthToken(_sendHeaders, token);
    final res = client.patch(uri, body: body, headers: headers);
    client.close();
    return res;
  }

  static Future<http.Response> delete(Uri uri,
      {String token = '', http.Client client}) {
    client ??= http.Client();
    final headers = _addAuthToken(_acceptHeaders, token);
    final res = client.delete(uri, headers: headers);
    client.close();
    return res;
  }
}
