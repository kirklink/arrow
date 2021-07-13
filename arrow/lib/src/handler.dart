import 'endpoint.dart';
import 'pipeline.dart';

// abstract class RouteTemplate {
//   Route get route;
// }

// abstract class RouterConfig {}

class Handler {
  // final String method;
  // final String path;
  final Endpoint endpoint;
  final Pipeline pipeline;

  Handler(this.endpoint, this.pipeline);

  // const Route.get(this.path, this.handler, this.pipeline) : method = 'GET';
  // const Route.post(this.path, this.handler, this.pipeline) : method = 'POST';
}
