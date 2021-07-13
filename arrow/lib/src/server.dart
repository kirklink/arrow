import 'dart:io' as io;

import 'arrow.dart';
import 'router_builder.dart';
import 'request.dart';

class Server {
  RouterBuilder _router;
  int _port;

  Server(this._router, this._port);

  Future start({bool forceSSL: false}) async {
    final _server = await io.HttpServer.bind(io.InternetAddress.anyIPv4, _port);
    if (!Arrow.isOnProduction)
      print('Server listening on localhost, port ${_server.port}');
    await for (io.HttpRequest req in _server) {
      final reqUri = req.requestedUri;
      if (Arrow.isOnProduction && forceSSL && reqUri.scheme != 'https') {
        req.response.redirect(
            Uri.https(reqUri.authority, reqUri.path, reqUri.queryParameters),
            status: io.HttpStatus.movedPermanently);
      } else {
        try {
          _router.serve(Request(req)).then((_) {
            req.response.close();
          });
        } catch (e) {
          if (!Arrow.isOnProduction) {
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
