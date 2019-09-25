import 'dart:async';

import 'router.dart';
import 'server.dart';

/// An Arrow server.
class Arrow {

/// Starts the Arrow server with the provided [Router]. The [port] can be specified here but will be
/// overrode if the ARROW_PORT environment variable is set. Setting [forceSSL]
/// to true will redirect all http requests to https. [printRoutes] prints all
/// the configured routes to stdout when the server starts.
  Future run(Router router,
      {int port: 8080,
      bool forceSSL: false,
      bool printRoutes: false}) async {
    if (printRoutes) _printRoutes(router);
    Server server = Server(router, port: port);
    await server.start(forceSSL: forceSSL);
    return;
  }

  void _printRoutes(Router router) {
    router.printRoutes();
    return;
  }
}
