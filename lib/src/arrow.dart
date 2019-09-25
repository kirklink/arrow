import 'dart:async';

import 'router.dart';
import 'server.dart';

/// The main entry point to starting an Arrow server. Create an instance
/// and start it with [Arrow.run()].
class Arrow {
  RouterBuilder _routerBuilder;

/// Arrow is constructed with a [RouterBuilder] which provides the route 
/// configurations to the Arrow server.
  Arrow(this._routerBuilder);

/// Starts the Arrow server. The [port] can be specified here but will be
/// overrode if the ARROW_PORT environment variable is set. Setting [forceSSL]
/// to true will redirect all http requests to https. [printRoutes] prints all
/// the configured routes to stdout when the server starts.
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
