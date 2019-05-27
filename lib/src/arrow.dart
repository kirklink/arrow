import 'dart:async';

import 'router.dart';
import 'server.dart';
import 'environment.dart';

class Arrow {
  RouterBuilder _routerBuilder;

  Arrow(this._routerBuilder);

  Future run<T extends Environment>(
      {int port: 8080,
      bool forceSSL: false,
      bool printRoutes: false,
        T environment}) async {
    if (printRoutes) _printRoutes();
    Server server = Server(_routerBuilder(), port: port);
    await server.start(forceSSL: forceSSL, environment: environment);
    return;
  }

  void _printRoutes() {
    _routerBuilder().printRoutes();
    return;
  }
}
