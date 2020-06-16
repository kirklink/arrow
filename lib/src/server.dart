import 'dart:io';

import 'router.dart';
import 'request.dart';
import 'response.dart';

class Server {
  Router _router;
  int _port;
  Map<String, String> _env = Platform.environment;
  bool _onProduction;

  
  bool _isOnProduction() {
    if (_onProduction == null) {
      // if (_env['ARROW_ENVIRONMENT'] == null) {
      //   throw Exception('ARROW_ENVIRONMENT should be "Production" for production or any other string if not on production.');
      // }
      if (_env['ARROW_ENVIRONMENT'] != null) {
        _onProduction = _env['ARROW_ENVIRONMENT'].toLowerCase() == 'production';
      } else {
        _onProduction = false;
      }  
    }
    return _onProduction;
  }
  
  bool get onProduction {
    return _isOnProduction();
  }
        

  Server(this._router, {int port}) {
    int p;
    if (_env['ARROW_PORT'] != null) {
      p = int.tryParse(_env['ARROW_PORT']);
    };
    if (p == null && _env['ARROW_PORT'] != null) {
      throw Exception(
          'ARROW_PORT could not be converted to integer: ${_env['ARROW_PORT']}');
    }
    if (p != null) {
      this._port = p;
    } else if (port != null) {
      this._port = port;
    } else {
      this._port = 8080;
    }
  }

  Future start({bool forceSSL: false}) async {
    final _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
    if (!onProduction) print(
        'Server listening on localhost, port ${_server.port}');
    await for (HttpRequest req in _server) {
      final reqUri = req.requestedUri;
      if (onProduction && forceSSL && reqUri.scheme != 'https') {
        req.response.redirect(
            Uri.https(reqUri.authority, reqUri.path, reqUri.queryParameters),
            status: HttpStatus.movedPermanently);
      } else {
        try {
          final r = Request(req);
          await _router.serve(r).then((Response res) {
            res.complete();
            req.response.close();
          });
        } catch (e) {
          if (!onProduction) {
            print('!! -- Unrecovered Server Error START -- !!');
            print(e);
            print('!! -- Unrecovered Server Error END -- !!');
          }

        } finally {
          req.response.close();
        }
      }
    }
  }
}
