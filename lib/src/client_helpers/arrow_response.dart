
import 'dart:convert' show json;

class ArrowResponse {
  final bool ok;
  final Map<String, Object> data;
  final String errorMsg;
  final Map<String, Object> errors;

  ArrowResponse._(this.ok, this.data, this.errorMsg, this.errors);

  factory ArrowResponse(String responseBody) {
    if (responseBody == null || responseBody.isEmpty) {
      final _ok = false;
      final _data = const <String, dynamic>{};
      final _errorMsg = 'No body was returned from the server.';
      final _errors = {'serverResponse': 'No body was returned from the server.'};
      return ArrowResponse._(_ok, _data, _errorMsg, _errors);
    } else {
      final body = json.decode(responseBody) as Map<String, Object>;
      final _ok = body['ok'] ?? false;
      final _data = body['data'] ?? const <String, Object>{};
      final _errorMsg = body['errorMessage'] ?? 'An incompatible response format was returned.';
      final _errors = body['errors'] ?? {'serverResponse': 'An incompatible response format was returned.'};
      return ArrowResponse._(_ok, _data, _errorMsg, _errors);
    }
  }

}