import 'dart:io' as io;

import 'router.dart';
import 'request.dart';
import 'response.dart';

class Server {
  Router _router;
  int _port;
  Map<String, String> _env = io.Platform.environment;
  bool _onProduction;

  bool _isOnProduction() {
    if (_onProduction == null) {
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

  Server(this._router, int port) {
    if (port != null) {
      this._port = port;
    } else {
      this._port = 8080;
    }
  }

  Future start({bool forceSSL: false}) async {
    final _server = await io.HttpServer.bind(io.InternetAddress.anyIPv4, _port);
    if (!onProduction)
      print('Server listening on localhost, port ${_server.port}');
    var count = 1;
    await for (io.HttpRequest req in _server) {
      final reqUri = req.requestedUri;
      if (onProduction && forceSSL && reqUri.scheme != 'https') {
        req.response.redirect(
            Uri.https(reqUri.authority, reqUri.path, reqUri.queryParameters),
            status: io.HttpStatus.movedPermanently);
      } else {
        try {
          print('serve: $count');
          _router.serve(Request(req)).then((Response res) {
            res.complete();
            req.response.close();
          });
        } catch (e) {
          if (!onProduction) {
            print('!! -- Unrecovered Server Error START -- !!');
            print(e);
            print('!! -- Unrecovered Server Error END -- !!');
          }
          req.response.close();
        }
      }
    }
  }
}
