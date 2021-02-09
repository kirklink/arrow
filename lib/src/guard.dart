import 'package:arrow/arrow.dart';

import 'request.dart';

class GuardResult {
  final bool allows;
  final Request request;

  GuardResult(this.allows, this.request);
}

class GuardBuilder {
  final Guard function;
  GuardBuilder(this.function);
  Future<GuardResult> evaluate(Request req) {
    return function(req);
  }
}

typedef Guard = Future<GuardResult> Function(Request req);

// typedef GuardFunction GuardBuilder(GuardFunction guardFunction);

// GuardFunction guard(Request req, GuardBuilder f) {
//   return f(req);
// }
