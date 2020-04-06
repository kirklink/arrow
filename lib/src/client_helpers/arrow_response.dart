class ArrowResponse {
  bool _ok;
  Map<String, Object> _data;
  String _errorMsg;
  Map<String, String> _errors;

  ArrowResponse(Map<String, Object> serverResponse) {
    _ok = serverResponse['ok'];
    _data = serverResponse['data'];
    _errorMsg = serverResponse['errorMessage'];
    _errors = serverResponse['errors'];
  }

  bool get ok => _ok;
  Map<String, Object> get data => _data;
  String get errorMsg => _errorMsg;
  Map<String, String> get errors => _errors;


}