import 'dart:io' as io;

import 'arrow.dart';
import 'router.dart';
import 'request.dart';
import 'response.dart';

class Server {
  Router _router;
  int _port;

  Server(this._router, int port) {
    this._port = port != null ? port : 8080;
  }

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
          _router.serve(Request(req)).then((Response res) {
            res.complete();
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
