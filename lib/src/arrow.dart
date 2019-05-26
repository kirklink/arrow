import 'dart:async';

import 'router.dart';
import 'server.dart';
import 'service.dart';

class Arrow {
  RouterBuilder _routerBuilder;

  Arrow(this._routerBuilder);

  Future run<T extends Service>(
      {int port: 8080,
      bool forceSSL: false,
      bool printRoutes: false,
        T services}) async {
    if (printRoutes) _printRoutes();
    Server server = Server(_routerBuilder(), port: port);
    await server.start(forceSSL: forceSSL, service: services);
    return;
  }

  void _printRoutes() {
    _routerBuilder().printRoutes();
    return;
  }
}
