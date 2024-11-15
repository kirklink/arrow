import 'dart:async';

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
  Future run(RouterBuilder routerBuilder,
      {int port = 8080,
      bool forceSSL = false,
      bool printRoutes = false}) async {
    final router = routerBuilder();
    if (printRoutes) {
      _printRoutes(router);
    }
    ;
    final server = Server(router, port);
    await server.start(forceSSL: forceSSL, isOnProduction: isOnProduction);
    return;
  }

  void _printRoutes(Router router) {
    router.printRoutes();
    return;
  }

  String? _environment;

  String get environment {
    if (_environment == null) {
      _environment = String.fromEnvironment('BUILD_ENV', defaultValue: '');
    }
    return _environment!;
  }

  bool get isOnProduction => environment == 'production';
  bool get isOnStaging => environment == 'staging';
  bool get isOnDevelopment => environment == 'development';
}
//   /// Returns true if the environment variable BUILD_ENV is 'production'
//   static final isOnProduction =
//       const String.fromEnvironment('BUILD_ENV', defaultValue: '') ==
//           'production';

//   /// Returns true if the environment variable BUILD_ENV is 'staging'
//   static final isOnStaging =
//       const String.fromEnvironment('BUILD_ENV', defaultValue: '') == 'staging';

//   /// Returns true if the environment variable BUILD_ENV is 'development'
//   static final isOnDevelopment =
//       const String.fromEnvironment('BUILD_ENV', defaultValue: '') ==
//           'development';

//   /// Returns the environment variable BUILD_ENV
//   static final environment =
//       const String.fromEnvironment('BUILD_ENV', defaultValue: '');
// }
