import 'dart:async';
import 'dart:convert' show json;
import 'dart:io' as io;

import 'router.dart';
import 'request.dart';

class Server {
  Router _router;
  int _port;
  bool _compress;
  Duration? _requestTimeout;
  Duration _shutdownTimeout;

  io.HttpServer? _server;
  int _inFlightRequests = 0;
  Completer<void>? _drainCompleter;
  bool _shuttingDown = false;

  /// Creates an Arrow server.
  ///
  /// [compress] enables gzip compression for clients that send
  /// `Accept-Encoding: gzip`. Defaults to `true`.
  ///
  /// [requestTimeout] sets a maximum duration for request processing.
  /// If the pipeline (middleware + handler) exceeds this duration, the
  /// server responds with 408 Request Timeout and closes the connection.
  ///
  /// [shutdownTimeout] is the maximum time to wait for in-flight requests
  /// to complete during graceful shutdown. Defaults to 30 seconds.
  Server(this._router, this._port,
      {bool compress = true,
      Duration? requestTimeout,
      Duration shutdownTimeout = const Duration(seconds: 30)})
      : _compress = compress,
        _requestTimeout = requestTimeout,
        _shutdownTimeout = shutdownTimeout;

  Future start({bool isOnProduction = false, bool forceSSL = false}) async {
    _server = await io.HttpServer.bind(io.InternetAddress.anyIPv4, _port);
    _server!.autoCompress = _compress;
    if (!isOnProduction)
      print('Server listening on localhost, port ${_server!.port}');

    _listenForShutdownSignals(isOnProduction);

    await for (io.HttpRequest req in _server!) {
      if (_shuttingDown) {
        // Reject new requests during shutdown.
        req.response.statusCode = io.HttpStatus.serviceUnavailable;
        req.response.headers.set(io.HttpHeaders.contentTypeHeader,
            'application/json; charset=utf-8');
        req.response.write(json.encode({
          'ok': false,
          'errorMessage': 'Server is shutting down',
          'errors': const {},
        }));
        req.response.close();
        continue;
      }

      final reqUri = req.requestedUri;
      if (isOnProduction && forceSSL && reqUri.scheme != 'https') {
        req.response.redirect(
            Uri.https(reqUri.authority, reqUri.path, reqUri.queryParameters),
            status: io.HttpStatus.movedPermanently);
      } else {
        _inFlightRequests++;
        try {
          Future<void> pipeline = _router.serve(Request(req)).then((_) {
            req.response.close();
          }).whenComplete(() {
            _inFlightRequests--;
            if (_shuttingDown && _inFlightRequests == 0) {
              _drainCompleter?.complete();
            }
          });
          if (_requestTimeout != null) {
            pipeline.timeout(_requestTimeout!, onTimeout: () {
              _writeTimeout(req);
            });
          }
        } catch (e) {
          _inFlightRequests--;
          if (!isOnProduction) {
            print('!! -- Unrecovered Server Error START -- !!');
            print(e);
            print('!! -- Unrecovered Server Error END -- !!');
          }
          req.response.close();
          if (_shuttingDown && _inFlightRequests == 0) {
            _drainCompleter?.complete();
          }
        }
      }
    }
  }

  void _listenForShutdownSignals(bool isOnProduction) {
    void shutdown(String signal) async {
      if (_shuttingDown) return; // Ignore duplicate signals.
      _shuttingDown = true;
      if (!isOnProduction) print('\n$signal received. Shutting down...');

      if (_inFlightRequests > 0) {
        if (!isOnProduction)
          print('Waiting for $_inFlightRequests in-flight request(s)...');
        _drainCompleter = Completer<void>();
        await _drainCompleter!.future
            .timeout(_shutdownTimeout, onTimeout: () {
          if (!isOnProduction)
            print('Shutdown timeout reached. Forcing close.');
        });
      }

      await _server?.close();
      if (!isOnProduction) print('Server stopped.');
    }

    // SIGINT (Ctrl+C) — always available.
    io.ProcessSignal.sigint.watch().listen((_) => shutdown('SIGINT'));

    // SIGTERM — not available on Windows.
    if (!io.Platform.isWindows) {
      io.ProcessSignal.sigterm.watch().listen((_) => shutdown('SIGTERM'));
    }
  }

  void _writeTimeout(io.HttpRequest req) {
    try {
      final body = json.encode({
        'ok': false,
        'errorMessage': 'Request Timeout',
        'errors': const {},
      });
      req.response.statusCode = io.HttpStatus.requestTimeout;
      req.response.headers.set(
          io.HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      req.response.write(body);
    } catch (_) {
      // Response may already be partially written; ignore write errors.
    } finally {
      req.response.close();
    }
  }
}
