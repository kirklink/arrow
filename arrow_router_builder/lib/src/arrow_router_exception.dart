class ArrowRouterBuilderException implements Exception {
  String cause;
  ArrowRouterBuilderException(this.cause);

  String toString() => cause;
}
