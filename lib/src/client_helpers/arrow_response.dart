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



}