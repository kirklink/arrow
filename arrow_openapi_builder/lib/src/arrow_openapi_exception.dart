class ArrowOpenapiBuilderException implements Exception {
  String cause;
  ArrowOpenapiBuilderException(this.cause);

  String toString() => cause;
}
