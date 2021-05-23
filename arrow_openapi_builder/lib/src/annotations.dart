class Contact {
  final String name;
  final String url;
  final String email;

  const Contact({this.name = '', this.url = '', this.email = ''});
}

class License {
  final String name;
  final String url;

  const License(this.name, {this.url = ''});
}

class OpenApiRouter {
  final String title;
  final String description;
  final String termsOfService;
  final Contact contact;
  final License license;
  final String version;

  const OpenApiRouter(this.title, this.version,
      {this.description = '',
      this.termsOfService = '',
      this.contact = const Contact(),
      this.license = const License('')});
}

class OpenApiRoute {
  final Type requestModel;
  final Type responseModel;

  const OpenApiRoute(this.requestModel, this.responseModel);
}

class OpenApiModel {
  const OpenApiModel();
}

class OpenApiField {
  final bool ignoreOnRequest;
  final bool ignoreOnResponse;
  const OpenApiField(
      {this.ignoreOnRequest = false, this.ignoreOnResponse = false});
}
