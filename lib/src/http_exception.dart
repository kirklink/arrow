/// Base class for throwable HTTP errors that automatically convert
/// to Arrow's standard error response format.
///
/// Throw an [HttpException] from any handler or middleware to short-circuit
/// the pipeline and return an error response.
///
/// ```dart
/// router.get('/users/{id}', (req) async {
///   final user = await findUser(req.params.get('id'));
///   if (user == null) throw NotFoundException('User not found');
///   return req.respond.ok(data: user.toJson());
/// });
/// ```
class HttpException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, Object> errors;

  const HttpException(this.statusCode, this.message,
      {this.errors = const <String, Object>{}});

  @override
  String toString() => 'HttpException($statusCode): $message';
}

/// 400 Bad Request — invalid input, validation failure, malformed request.
class BadRequestException extends HttpException {
  const BadRequestException(
      [String message = 'Bad Request',
      Map<String, Object> errors = const <String, Object>{}])
      : super(400, message, errors: errors);
}

/// 401 Unauthorized — missing or invalid authentication.
class UnauthorizedException extends HttpException {
  const UnauthorizedException(
      [String message = 'Unauthorized',
      Map<String, Object> errors = const <String, Object>{}])
      : super(401, message, errors: errors);
}

/// 403 Forbidden — authenticated but not authorized for this resource.
class ForbiddenException extends HttpException {
  const ForbiddenException(
      [String message = 'Forbidden',
      Map<String, Object> errors = const <String, Object>{}])
      : super(403, message, errors: errors);
}

/// 404 Not Found — resource does not exist.
class NotFoundException extends HttpException {
  const NotFoundException(
      [String message = 'Not Found',
      Map<String, Object> errors = const <String, Object>{}])
      : super(404, message, errors: errors);
}

/// 409 Conflict — request conflicts with current server state.
class ConflictException extends HttpException {
  const ConflictException(
      [String message = 'Conflict',
      Map<String, Object> errors = const <String, Object>{}])
      : super(409, message, errors: errors);
}

/// 500 Internal Server Error — unexpected server failure.
class InternalServerException extends HttpException {
  const InternalServerException(
      [String message = 'Internal Server Error',
      Map<String, Object> errors = const <String, Object>{}])
      : super(500, message, errors: errors);
}
