import 'package:http/http.dart' as http;

import 'request.dart';
import 'response.dart';

Future<Response> forward(Request req, String host,
    {String path, Map<String, String> params}) async {
  path = path != null ? path : req.uri.path;
  params = params != null ? params : req.uri.queryParameters;
  String jwt;
  Uri uri;
  if (req.isOnProd) {
    final String metadataUrl =
        'http://metadata/computeMetadata/v1/instance/service-accounts/default/identity?audience=';
    uri = Uri.parse('https://${host}${path}').replace(queryParameters: params);
    final tokenURL = metadataUrl + uri.toString();
    final tokenResponse =
        await http.get(tokenURL, headers: {'Metadata-Flavor': 'Google'});
    jwt = tokenResponse.body;
  } else {
    print(host + path);
    uri = Uri.parse('http://${host}${path}');
    print(uri.toString());
  }
  var forwardReq = http.Request(req.method, uri);
  forwardReq.body = req.content.encode();
  forwardReq.headers
      .putIfAbsent('content-type', () => req.headers.contentType.value);
  if (jwt != null)
    forwardReq.headers.putIfAbsent('Authorization', () => 'Bearer $jwt');
  print(forwardReq.headers);
  http.StreamedResponse next = await forwardReq.send();
  var body = await next.stream.bytesToString();
  var res = req.respond(wrapped: false);
  res.send.relayJson(body, next.statusCode);
  return res;
}
