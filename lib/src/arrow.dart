import 'dart:async';

import 'router.dart';
import 'server.dart';
import 'backends.dart';

class Arrow {
  RouterBuilder _routerBuilder;

  Arrow(this._routerBuilder);

  Future run<T extends Backends>(
      {int port: 8080,
      bool forceSSL: false,
      bool printRoutes: false,
      T backends}) async {
    if (printRoutes) _printRoutes();
    Server server = Server(_routerBuilder(), port: port);
    await server.start(forceSSL: forceSSL, backends: backends);
    return;
  }

  void _printRoutes() {
    _routerBuilder().printRoutes();
    return;
  }
}
