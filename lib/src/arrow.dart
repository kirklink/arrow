import 'dart:async';
import 'dart:io';

import 'router.dart';
import 'server.dart';

/// An Arrow server.
class Arrow {

/// Starts the Arrow server with the provided [Router]. 
/// 
/// The [port] can be specified here but the ARROW_PORT environment variable
/// will override this value if ARROW_PORT is found in the environment. Setting 
/// [forceSSL] to true will redirect all http requests to https. [printRoutes] prints 
/// all the configured routes to stdout when the server starts.
  Future run(Router router,
      {int port: 8080,
      bool forceSSL: false,
      bool printRoutes: false,
      bool useEnvPORT: false}) async {
    if (printRoutes) _printRoutes(router);
    var suppliedPort = port;
    int envPortInt;
    if (useEnvPORT) {
      var envPort = Platform.environment['PORT'];
      envPortInt = int.tryParse(envPort);
    }
    if (envPortInt != null) {
      suppliedPort = envPortInt;
    }
    Server server = Server(router, port: suppliedPort);
    await server.start(forceSSL: forceSSL);
    return;
  }

  void _printRoutes(Router router) {
    router.printRoutes();
    return;
  }

  static final bool isOnProduction = Platform.environment['ARROW_ENVIRONMENT']?.toLowerCase() == 'production';

  static final environment = Platform.environment;
}
