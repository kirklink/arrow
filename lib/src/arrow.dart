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
      {int port = 8080,
      bool forceSSL = false,
      bool printRoutes = false}) async {
    if (printRoutes) _printRoutes(router);
    Server server = Server(router, port);
    await server.start(forceSSL: forceSSL);
    return;
  }

  void _printRoutes(Router router) {
    router.printRoutes();
    return;
  }

  static final isOnProduction = const bool.hasEnvironment('ENVIRONMENT')
      ? const String.fromEnvironment('ENVIRONMENT') == 'production'
      : Platform.environment['ENVIRONMENT'] == 'production';
  static final isOnStaging = const bool.hasEnvironment('ENVIRONMENT')
      ? const String.fromEnvironment('ENVIRONMENT') == 'staging'
      : Platform.environment['ENVIRONMENT'] == 'staging';
  static final isOnDevelopment = const bool.hasEnvironment('ENVIRONMENT')
      ? const String.fromEnvironment('ENVIRONMENT') == 'development'
      : Platform.environment['ENVIRONMENT'] == 'development';

  static final environment = const bool.hasEnvironment('ENVIRONMENT')
      ? const String.fromEnvironment('ENVIRONMENT')
      : Platform.environment['ENVIRONMENT'] ?? '';

  static final envVariables = Platform.environment;

  static final port = const bool.hasEnvironment('PORT')
      ? const String.fromEnvironment('PORT')
      : Platform.environment['PORT'] ?? '8080';
}
