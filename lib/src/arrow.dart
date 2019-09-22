import 'dart:async';

import 'router.dart';
import 'server.dart';

class Arrow {
  RouterBuilder _routerBuilder;

  Arrow(this._routerBuilder);

  Future run(
      {int port: 8080,
      bool forceSSL: false,
      bool printRoutes: false}) async {
    if (printRoutes) _printRoutes();
    Server server = Server(_routerBuilder(), port: port);
    await server.start(forceSSL: forceSSL);
    return;
  }

  void _printRoutes() {
    _routerBuilder().printRoutes();
    return;
  }
}
