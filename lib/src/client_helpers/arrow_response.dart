import 'package:http/http.dart' show Response;
import 'dart:convert' show json;

class ArrowResponse {
  bool _ok;
  Map<String, Object> _data;
  String _errorMsg;
  Map<String, String> _errors;

  ArrowResponse(Response serverResponse) {
    final body = json.decode(serverResponse.body) as Map<String, Object>;
    
    if (body.containsKey('ok')) {
      _ok = body['ok'] as bool;
    } else {
      _ok = serverResponse.statusCode >= 200 && serverResponse.statusCode < 300;
    }

    if (body.containsKey('data')) {
      _data = body['data'] as Map<String, Object>;
    } else {
      _data = const <String, Object>{};
    }
    
    if (body.containsKey('errorMessage')) {
      _errorMsg = body['errorMessage'] as String;
    } else if (_ok){
      _errorMsg = '';
    } else {
      _errorMsg = 'No body was returned from the server.';
    }

    if (body.containsKey('errors')) {
      _errors = body['errors'] as Map<String, String>;
    } else if (_ok) {
      _errors = const <String, String>{};
    } else {
      _errors = {
        'responseError': 'No body was return from the server.'
      };
    }
  }

  bool get ok => _ok;
  Map<String, Object> get data => _data;
  String get errorMsg => _errorMsg;
  Map<String, String> get errors => _errors;


}