abstract class RouterMethods {
  static const String GET = 'GET';
  static const String POST = 'POST';
  static const String PUT = 'PUT';
  static const String DELETE = 'DELETE';
  static const String PATCH = 'PATCH';
  static const String HEAD = 'HEAD';

  static final List<String> allowedMethods =
      new List.unmodifiable([GET, POST, PUT, DELETE, PATCH, HEAD]);
}
