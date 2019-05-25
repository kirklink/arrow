abstract class RouterMethods {
  static const String GET = 'GET';
  static const String POST = 'POST';
  static const String PUT = 'PUT';
  static const String DELETE = 'DELETE';

  static final List<String> allowedMethods =
      new List.unmodifiable([GET, POST, PUT, DELETE]);
}
