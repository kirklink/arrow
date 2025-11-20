/// OpenAPI annotations for Arrow framework

/// Marks a service with its backend URL for OpenAPI generation
class OpenApiService {
  final String backend;
  const OpenApiService(this.backend);
}

/// Marks a class for OpenAPI spec generation
class OpenApiSpec {
  const OpenApiSpec();
}

/// Contact information for OpenAPI spec
class OpenApiContact {
  final String name;
  final String url;
  final String email;

  const OpenApiContact({this.name = '', this.url = '', this.email = ''});
}

/// License information for OpenAPI spec
class OpenApiLicense {
  final String name;
  final String url;

  const OpenApiLicense(this.name, {this.url = ''});
}

/// Metadata for OpenAPI spec generation
class OpenApiMeta {
  final String title;
  final String description;
  final String termsOfService;
  final OpenApiContact contact;
  final OpenApiLicense license;
  final String version;

  const OpenApiMeta(
    this.title,
    this.version, {
    this.description = '',
    this.termsOfService = '',
    this.contact = const OpenApiContact(),
    this.license = const OpenApiLicense(''),
  });
}

/// Marks a class as an OpenAPI model
class OpenApiModel {
  final bool isModel;
  const OpenApiModel(this.isModel);
}

/// Configures field behavior in OpenAPI generation
class OpenApiField {
  final bool ignoreOnRequest;
  final bool ignoreOnResponse;

  const OpenApiField({
    this.ignoreOnRequest = false,
    this.ignoreOnResponse = false,
  });
}
