/// Router and Route annotations for Arrow framework

/// Marks a class for route configuration
/// Use this instead of manually creating a Router with cascade operators
class RouterConfig {
  const RouterConfig();
}

/// Defines a route annotation for code generation
/// Use @RouteHandler.get(), @RouteHandler.post(), etc.
class RouteHandler {
  final String method;
  final String path;

  const RouteHandler.get(this.path) : method = 'GET';
  const RouteHandler.post(this.path) : method = 'POST';
  const RouteHandler.put(this.path) : method = 'PUT';
  const RouteHandler.delete(this.path) : method = 'DELETE';
  const RouteHandler.patch(this.path) : method = 'PATCH';
}
