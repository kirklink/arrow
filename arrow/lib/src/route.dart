import 'package:arrow/arrow.dart';
import 'package:arrow/src/pipeline.dart';

abstract class RouteTemplate {
  Route get route;
}

abstract class RouterConfig {
  
}

class Route {
  final String method;
  final String path;
  final Handler handler;
  final Pipeline pipeline;

  const Route.get(this.path, this.handler, this.pipeline) : method = 'GET';
  const Route.post(this.path, this.handler, this.pipeline) : method = 'POST';
}
