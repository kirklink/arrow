import 'dart:io';
import 'package:uri/uri.dart' as u;

import 'arrow_exception.dart';
import 'responder.dart';
import 'parameters.dart';
import 'content.dart';
import 'context.dart';
import 'internal_messenger.dart';

class Request {
  Content? _content;
  final HttpRequest innerRequest;
  final context = Context();
  final messenger = InternalMessenger();
  final params = Parameters();
  bool _isAlive = true;
  late Responder _responder;

  Request(this.innerRequest) {
    this._responder = Responder(this);
  }

  bool get isAlive => _isAlive;
  void cancel() => _isAlive = false;
  Content? get content => _content;

  // Convenience accessors.
  String get method => innerRequest.method;
  Uri get uri => u.UriBuilder.fromUri(innerRequest.uri).build();
  HttpHeaders get headers => innerRequest.headers;

  set content(Content? content) {
    if (_content != null) throw ArrowException('Content is already loaded.');
    _content = content;
  }

  Responder get respond => _responder;

  // Query parameter helpers.

  /// Get a single query parameter value by key.
  ///
  /// Returns the value for the given [key], or [defaultValue] if the
  /// parameter is not present. Returns `null` if the parameter is missing
  /// and no default is provided.
  ///
  /// ```dart
  /// // GET /users?page=2&sort=name
  /// final page = req.queryParam('page');           // '2'
  /// final sort = req.queryParam('sort');            // 'name'
  /// final missing = req.queryParam('missing');      // null
  /// final withDefault = req.queryParam('limit', defaultValue: '10'); // '10'
  /// ```
  String? queryParam(String key, {String? defaultValue}) {
    return innerRequest.uri.queryParameters[key] ?? defaultValue;
  }

  /// Get all values for a query parameter key (for repeated params).
  ///
  /// Useful for parameters like `?tags=a&tags=b` which have multiple values.
  /// Returns an empty list if the parameter is not present.
  ///
  /// ```dart
  /// // GET /search?tags=dart&tags=flutter&tags=server
  /// final tags = req.queryParams('tags'); // ['dart', 'flutter', 'server']
  /// final empty = req.queryParams('missing'); // []
  /// ```
  List<String> queryParams(String key) {
    return innerRequest.uri.queryParametersAll[key] ?? [];
  }

  /// Get a query parameter as an integer.
  ///
  /// Parses the value for [key] as an integer. Returns [defaultValue] if
  /// the parameter is missing or cannot be parsed as an integer.
  ///
  /// ```dart
  /// // GET /users?page=2&limit=50
  /// final page = req.queryInt('page', defaultValue: 1);   // 2
  /// final limit = req.queryInt('limit', defaultValue: 20); // 50
  /// final bad = req.queryInt('missing');                    // null
  /// ```
  int? queryInt(String key, {int? defaultValue}) {
    final value = innerRequest.uri.queryParameters[key];
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  /// Get a query parameter as a boolean.
  ///
  /// Returns `true` for values 'true', '1', 'yes' (case-insensitive).
  /// Returns `false` for values 'false', '0', 'no' (case-insensitive).
  /// Returns [defaultValue] if the parameter is missing or unrecognized.
  ///
  /// ```dart
  /// // GET /users?active=true&verbose=1&debug=yes
  /// final active = req.queryBool('active');  // true
  /// final verbose = req.queryBool('verbose'); // true
  /// final debug = req.queryBool('debug');     // true
  /// final missing = req.queryBool('missing', defaultValue: false); // false
  /// ```
  bool? queryBool(String key, {bool? defaultValue}) {
    final value = innerRequest.uri.queryParameters[key]?.toLowerCase();
    if (value == null) return defaultValue;
    if (value == 'true' || value == '1' || value == 'yes') return true;
    if (value == 'false' || value == '0' || value == 'no') return false;
    return defaultValue;
  }
}
