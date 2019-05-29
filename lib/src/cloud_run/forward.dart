import 'package:http/http.dart' as http;

import 'package:arrow/src/request.dart';
import 'package:arrow/src/response.dart';

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
    uri = Uri.parse('http://${host}${path}');
  }
  var forwardReq = http.Request(req.method, uri);
  forwardReq.body = req.content.encode();
  forwardReq.headers['Content-Type'] = req.headers.contentType.value;
  if (jwt != null) forwardReq.headers['Authorization'] = 'Bearer $jwt';
  Response res;
  try {
    http.StreamedResponse next = await forwardReq.send();
    var body = await next.stream.bytesToString();
    res = req.respond(wrapped: false);
    res.send.relayJson(body, next.statusCode);
  } catch (e) {
    res = req.respond();
    res.send.serverError();
  } finally {
    return res;
  }
}
