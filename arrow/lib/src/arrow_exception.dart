class ArrowException implements Exception {
  final String message;

  ArrowException(this.message);

  @override
  String toString() => '$message';
}
