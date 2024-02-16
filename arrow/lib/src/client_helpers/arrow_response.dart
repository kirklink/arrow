import 'dart:convert' show jsonDecode;
import 'package:http/http.dart' as http;

class ArrowResponse {
  final bool ok;
  final Map<String, Object> data;
  final String errorMsg;
  final Map<String, Object> errors;
  final int statusCode;
  final String rawBody;

  ArrowResponse._(this.ok, this.data, this.errorMsg, this.errors,
      this.statusCode, this.rawBody);

  factory ArrowResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode > 299) {
      final body = jsonDecode(response.body) as Map<String, Object>;
      final _ok = false;
      final _data = const <String, dynamic>{};
      final _errorMsg = body['errorMessage'] ??
          'The server return a ${response.statusCode} error.';
      final _errors = body['errors'] ??
          {
            'serverResponse':
                'The server return a ${response.statusCode} error.'
          };
      return ArrowResponse._(
          _ok, _data as Map<String, Object>, _errorMsg as String, _errors as Map<String, Object>, response.statusCode, response.body);
    }

    if (response.body == null || response.body.isEmpty) {
      final _ok = false;
      final _data = const <String, dynamic>{};
      final _errorMsg = 'No body was returned from the server.';
      final _errors = {
        'serverResponse': 'No body was returned from the server.'
      };
      return ArrowResponse._(
          _ok, _data as Map<String, Object>, _errorMsg, _errors, response.statusCode, response.body);
    }

    final body = jsonDecode(response.body) as Map<String, Object>;
    final _ok = body['ok'] ?? false;
    final _data = body['data'] ?? const <String, Object>{};
    final _errorMsg =
        body['errorMessage'] ?? 'An incompatible response format was returned.';
    final _errors = body['errors'] ??
        {'serverResponse': 'An incompatible response format was returned.'};
    return ArrowResponse._(
        _ok as bool, _data as Map<String, Object>, _errorMsg as String, _errors as Map<String, Object>, response.statusCode, response.body);
  }
}
