class Router {
  const Router();
}

class Route {
  final String method;
  final String path;
  // final Type requestModel;
  // final Type responseModel;

  const Route.get(this.path) : method = 'GET';

  // const Route.get(this.path,
  //     {this.requestModel = Null, this.responseModel = Null})
  //     : method = 'GET';

  const Route.post(this.path) : method = 'POST';

  // const Route.post(this.path,
  //     {this.requestModel = Null, this.responseModel = Null})
  //     : method = 'POST';
}

class OpenApiService {
  final String backend;
  const OpenApiService(this.backend);
}

class OpenApiSpec {
  const OpenApiSpec();
}

class OpenApiContact {
  final String name;
  final String url;
  final String email;

  const OpenApiContact({this.name = '', this.url = '', this.email = ''});
}

class OpenApiLicense {
  final String name;
  final String url;

  const OpenApiLicense(this.name, {this.url = ''});
}

class OpenApiMeta {
  final String title;
  final String description;
  final String termsOfService;
  final OpenApiContact contact;
  final OpenApiLicense license;
  final String version;

  const OpenApiMeta(this.title, this.version,
      {this.description = '',
      this.termsOfService = '',
      this.contact = const OpenApiContact(),
      this.license = const OpenApiLicense('')});
}

class OpenApiModel {
  final bool isModel;
  const OpenApiModel(this.isModel);
}

class OpenApiField {
  final bool ignoreOnRequest;
  final bool ignoreOnResponse;
  const OpenApiField(
      {this.ignoreOnRequest = false, this.ignoreOnResponse = false});
}
