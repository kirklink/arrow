import 'request.dart';
import 'context.dart';
import 'internal_messenger.dart';

class Response {
  final Request? request;
  final Map<String, dynamic> data;
  final Map<String, String> errors;

  Response(this.request,
      {this.data = const <String, dynamic>{},
      this.errors = const <String, String>{}});

  bool get isAlive => request!.isAlive;
  int get statusCode => request!.innerRequest.response.statusCode;
  Context get context => request!.context;
  InternalMessenger get messenger => request!.messenger;

  void cancel() => request!.cancel();
}
