import 'dart:io';

import 'router.dart';
import 'request.dart';
import 'service.dart';
import 'global.dart';

class Server {
  Router _router;
  int _port;
  Map<String, String> _env = Platform.environment;

  bool get onProduction =>
      _env['ARROW_ENVIRONMENT'].toLowerCase() == 'production';

  Server(this._router, {int port}) {
    var p = int.tryParse(_env['PORT']);
    if (p == null && _env['PORT'] != null) {
      throw Exception(
          'Port provided from environment could not be converted to integer: ${_env['PORT']}');
    }
    if (p != null) {
//        print('Using port $p from environment.');
      this._port = p;
    } else if (port != null) {
      this._port = port;
    } else {
      this._port = 8080;
    }
  }

  Future start<T extends Service>({bool forceSSL: false, T service}) async {
    var _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
    if (!onProduction) print(
        'Server listening on localhost, port ${_server.port}');
    var onProd = onProduction;
    var validBackends = <String, String>{};
    _env.forEach((k, v) {
      if (k.toLowerCase().startsWith('service')) {
        validBackends[k] = v;
      }
    });
    service.fromMap(validBackends);
    Global({'ENV': _env, 'SERVICE': service});
    await for (HttpRequest req in _server) {
      var reqUri = req.requestedUri;
      if (onProd && forceSSL && reqUri.scheme != 'https') {
        req.response.redirect(
            Uri.https(reqUri.authority, reqUri.path, reqUri.queryParameters),
            status: HttpStatus.movedPermanently);
      } else {
        try {
          var r = Request(req);
          await _router.serve(r).then((res) {
            req.response.close();
          });
        } catch (e) {
          if (!onProduction) print('!! -- Unrecovered Server error -- !!');
          rethrow;
        } finally {
          req.response.close();
        }
      }
    }
  }
}
