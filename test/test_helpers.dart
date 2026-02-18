import 'dart:io';
import 'dart:async';
import 'dart:convert' show utf8;

/// Test helpers for Arrow framework tests
///
/// This library provides utilities for creating mock HTTP requests and servers
/// without the deadlock issues that occur with `await server.first`.
///
/// ## The Deadlock Problem
///
/// Using `await server.first` causes deadlocks:
/// 1. Client makes request and awaits response
/// 2. `server.first` awaits request
/// 3. Both are waiting for each other → DEADLOCK!
///
/// ## The Solution
///
/// Use `server.listen()` with a `Completer` instead. The listener is set up
/// before the client request is made, avoiding the deadlock.
///
/// ## Usage
///
/// ```dart
/// import '../test_helpers.dart';
///
/// void main() {
///   group('MyTests', () {
///     tearDownAll(() async {
///       await cleanupAllMockRequests();
///     });
///
///     test('should create request', () async {
///       final httpReq = await createMockHttpRequest();
///       // Use httpReq in your test
///       await cleanupMockRequest(httpReq);
///     });
///   });
/// }
/// ```

/// Creates a mock HttpRequest for testing without deadlocks
///
/// Creates a real HTTP server, makes a real request to it, captures the
/// HttpRequest object, and returns it for testing.
///
/// **Important:** Always call [cleanupMockRequest] or [cleanupAllMockRequests]
/// to avoid resource leaks.
///
/// ## Parameters
///
/// - [path] - The request path (default: '/test')
/// - [method] - HTTP method (default: 'GET')
/// - [headers] - Optional headers to include in the request
/// - [body] - Optional body content for POST/PUT requests
/// - [timeout] - Maximum time to wait for request (default: 5 seconds)
///
/// ## Example
///
/// ```dart
/// // Simple GET request
/// final req = await createMockHttpRequest();
///
/// // POST request with body
/// final req = await createMockHttpRequest(
///   path: '/api/users',
///   method: 'POST',
///   headers: {'Content-Type': 'application/json'},
///   body: '{"name": "Alice"}',
/// );
/// ```
Future<HttpRequest> createMockHttpRequest({
  String path = '/test',
  String method = 'GET',
  Map<String, String>? headers,
  Map<String, String>? cookies,
  String? body,
  List<int>? bodyBytes,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final server = await HttpServer.bind('localhost', 0);
  final port = server.port;

  // Use a Completer to capture the request
  final completer = Completer<HttpRequest>();

  // Set up listener to capture the first request
  late StreamSubscription subscription;
  subscription = server.listen((request) {
    if (!completer.isCompleted) {
      completer.complete(request);
      subscription.cancel();
    }
  });

  // Make the client request in the background
  final client = HttpClient();
  Future<HttpClientRequest> requestFuture;

  // Choose HTTP method
  switch (method.toUpperCase()) {
    case 'GET':
      requestFuture = client.get('localhost', port, path);
      break;
    case 'POST':
      requestFuture = client.post('localhost', port, path);
      break;
    case 'PUT':
      requestFuture = client.put('localhost', port, path);
      break;
    case 'DELETE':
      requestFuture = client.delete('localhost', port, path);
      break;
    case 'PATCH':
      requestFuture = client.patch('localhost', port, path);
      break;
    case 'HEAD':
      requestFuture = client.head('localhost', port, path);
      break;
    default:
      requestFuture = client.open(method, 'localhost', port, path);
  }

  requestFuture.then((request) {
    // Add custom headers if provided
    if (headers != null) {
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });
    }

    // Add cookies if provided
    if (cookies != null) {
      cookies.forEach((name, value) {
        request.cookies.add(Cookie(name, value));
      });
    }

    // Write body if provided
    if (bodyBytes != null) {
      request.add(bodyBytes);
    } else if (body != null) {
      request.write(body);
    }

    return request.close();
  }).then((response) {
    response.drain(); // Consume response
  }).catchError((e) {
    // Ignore errors - we're just triggering the request
  }).whenComplete(() {
    client.close();
    // Note: Don't close server yet - test needs the HttpRequest
  });

  // Wait for and return the server request with timeout
  final request = await completer.future.timeout(
    timeout,
    onTimeout: () {
      subscription.cancel();
      server.close();
      throw TimeoutException(
        'createMockHttpRequest timed out after ${timeout.inSeconds}s',
        timeout,
      );
    },
  );

  // Store server reference in request for cleanup
  _servers[request] = server;

  return request;
}

// Keep track of servers for cleanup
final Map<HttpRequest, HttpServer> _servers = {};

/// Clean up the server associated with a mock request
///
/// Call this after you're done with a mock HttpRequest to free resources.
/// If you forget to call this, resources will leak until [cleanupAllMockRequests]
/// is called (typically in `tearDownAll`).
///
/// ## Example
///
/// ```dart
/// test('my test', () async {
///   final req = await createMockHttpRequest();
///   // Use req...
///   await cleanupMockRequest(req);  // Clean up
/// });
/// ```
Future<void> cleanupMockRequest(HttpRequest request) async {
  final server = _servers.remove(request);
  if (server != null) {
    await server.close();
  }
}

/// Clean up all mock request servers
///
/// Closes all HTTP servers created by [createMockHttpRequest] that haven't
/// been cleaned up yet. This is typically called in `tearDownAll` to ensure
/// no resources leak between test runs.
///
/// ## Example
///
/// ```dart
/// void main() {
///   group('MyTests', () {
///     tearDownAll(() async {
///       await cleanupAllMockRequests();  // Clean up any remaining servers
///     });
///   });
/// }
/// ```
Future<void> cleanupAllMockRequests() async {
  final servers = List.from(_servers.values);
  _servers.clear();
  for (final server in servers) {
    await server.close();
  }
}

/// Creates a mock GET request
///
/// Convenience wrapper around [createMockHttpRequest] for GET requests.
Future<HttpRequest> createMockGetRequest({String path = '/test'}) {
  return createMockHttpRequest(path: path, method: 'GET');
}

/// Creates a mock POST request with JSON body
///
/// Convenience wrapper around [createMockHttpRequest] for POST requests
/// with JSON content.
///
/// ## Example
///
/// ```dart
/// final req = await createMockPostRequest(
///   path: '/api/users',
///   body: '{"name": "Alice", "age": 30}',
/// );
/// ```
Future<HttpRequest> createMockPostRequest({
  String path = '/test',
  String? body,
}) {
  return createMockHttpRequest(
    path: path,
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
}

/// Creates a mock PUT request with JSON body
///
/// Convenience wrapper around [createMockHttpRequest] for PUT requests
/// with JSON content.
Future<HttpRequest> createMockPutRequest({
  String path = '/test',
  String? body,
}) {
  return createMockHttpRequest(
    path: path,
    method: 'PUT',
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
}

/// Creates a mock DELETE request
///
/// Convenience wrapper around [createMockHttpRequest] for DELETE requests.
Future<HttpRequest> createMockDeleteRequest({String path = '/test'}) {
  return createMockHttpRequest(path: path, method: 'DELETE');
}

/// Creates a mock PATCH request with JSON body
///
/// Convenience wrapper around [createMockHttpRequest] for PATCH requests
/// with JSON content.
Future<HttpRequest> createMockPatchRequest({
  String path = '/test',
  String? body,
}) {
  return createMockHttpRequest(
    path: path,
    method: 'PATCH',
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
}

/// A file to include in a mock multipart request.
class MockMultipartFile {
  final String fieldName;
  final String filename;
  final String contentType;
  final List<int> bytes;
  MockMultipartFile(this.fieldName, this.filename, this.contentType, this.bytes);
}

/// Creates a mock multipart/form-data POST request for testing file uploads.
///
/// Builds a proper multipart body from [fields] and [files], sets the
/// Content-Type header with boundary, and returns the captured HttpRequest.
///
/// ```dart
/// final req = await createMockMultipartRequest(
///   fields: {'description': 'My photo'},
///   files: [MockMultipartFile('avatar', 'photo.jpg', 'image/jpeg', [0xFF, 0xD8])],
/// );
/// ```
Future<HttpRequest> createMockMultipartRequest({
  String path = '/test',
  Map<String, String> fields = const {},
  List<MockMultipartFile> files = const [],
  String? boundary,
}) {
  boundary ??= '----ArrowTestBoundary';

  final bodyParts = <List<int>>[];

  for (final entry in fields.entries) {
    bodyParts.add(utf8.encode(
        '--$boundary\r\n'
        'content-disposition: form-data; name="${entry.key}"\r\n'
        '\r\n'
        '${entry.value}\r\n'));
  }

  for (final file in files) {
    bodyParts.add(utf8.encode(
        '--$boundary\r\n'
        'content-disposition: form-data; name="${file.fieldName}"; '
        'filename="${file.filename}"\r\n'
        'content-type: ${file.contentType}\r\n'
        '\r\n'));
    bodyParts.add(file.bytes);
    bodyParts.add(utf8.encode('\r\n'));
  }

  bodyParts.add(utf8.encode('--$boundary--\r\n'));

  final allBytes = bodyParts.expand((b) => b).toList();

  return createMockHttpRequest(
    path: path,
    method: 'POST',
    headers: {'Content-Type': 'multipart/form-data; boundary=$boundary'},
    bodyBytes: allBytes,
  );
}
