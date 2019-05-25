import 'dart:io';

import 'router.dart';
import 'request.dart';
import 'backends.dart';
import 'global.dart';

class Server {
  Router _router;
  int _port;

  Server(this._router, {int port}) {
    Map<String, String> env = Platform.environment;
    var p = int.tryParse(env['PORT']);
    if (p == null && env['PORT'] != null) {
      throw Exception(
          'Port provided from environment could not be converted to integer: ${env['PORT']}');
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

  Future start<T extends Backends>({bool forceSSL: false, T backends}) async {
    var _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
//    print('Server listening on localhost, port ${_server.port}');
    Map<String, String> env = Platform.environment;
    bool onProduction = env['ARROW_ENVIRONMENT'].toLowerCase() == 'production';
    var validBackends = <String, String>{};
    env.forEach((k, v) {
      if (k.toLowerCase().startsWith('backend')) {
        validBackends[k] = v;
      }
    });
    backends.fromJson(validBackends);
    Global({'ENV': env, 'BACKENDS': backends});
    await for (HttpRequest req in _server) {
      var reqUri = req.requestedUri;
      if (onProduction && forceSSL && reqUri.scheme != 'https') {
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
