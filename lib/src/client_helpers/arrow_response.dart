import 'package:http/http.dart' show Response;
import 'dart:convert' show json;

class ArrowResponse {
  bool _ok;
  Map<String, Object> _data;
  String _errorMsg;
  Map<String, String> _errors;

  ArrowResponse(Response serverResponse) {
    final body = json.decode(serverResponse.body);
    _ok = body['ok'];
    _data = body['data'];
    _errorMsg = body['errorMessage'];
    _errors = body['errors'];
  }

  bool get ok => _ok;
  Map<String, Object> get data => _data;
  String get errorMsg => _errorMsg;
  Map<String, String> get errors => _errors;


}