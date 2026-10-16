import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'protocol.dart';

/// Fixed origins; never follows redirects with bearer credentials.
class OpenAiTransport {
  OpenAiTransport({HttpClient Function()? clientFactory})
      : _createClient = clientFactory ?? HttpClient.new {
    _client = _createClient()..connectionTimeout = const Duration(seconds: 20);
  }
  final HttpClient Function() _createClient;
  late final HttpClient _client;
  HttpClient? _streamClient;

  Future<HttpClientResponse> _request(String method, Uri uri, {
    Map<String, String> headers = const {}, String? body, HttpClient? client,
  }) async {
    if (uri.scheme != 'https' || !['auth.openai.com', 'api.openai.com'].contains(uri.host) ||
        uri.port != 443 || uri.userInfo.isNotEmpty) {
      throw const ConnectionFailure('Unexpected OpenAI service address.');
    }
    final request = await (client ?? _client).openUrl(method, uri)
        .timeout(const Duration(seconds: 25));
    request.followRedirects = false;
    headers.forEach(request.headers.set);
    if (body != null) request.write(body);
    return request.close().timeout(const Duration(seconds: 40));
  }

  Future<Map<String, dynamic>> json(String method, Uri uri, {
    Map<String, String> headers = const {}, Map<String, String>? form,
  }) async {
    final response = await _request(method, uri, headers: {
      ...headers, if (form != null) 'Content-Type': 'application/x-www-form-urlencoded',
    }, body: form == null ? null : Uri(queryParameters: form).query);
    final text = await utf8.decoder.bind(response).join().timeout(const Duration(seconds: 30));
    Object? body;
    try { body = text.isEmpty ? <String, dynamic>{} : jsonDecode(text); } catch (_) { body = null; }
    if (response.statusCode != 200) {
      throw serviceFailure(response.statusCode, body, response.headers.value('x-request-id'));
    }
    if (body is! Map<String, dynamic>) throw const ConnectionFailure('OpenAI returned an unexpected response.');
    return body;
  }

  Future<Map<String, dynamic>> discovery() async {
    final result = await json('GET', Uri.parse('$issuer/.well-known/openid-configuration'));
    if (result['issuer'] != issuer) throw const ConnectionFailure('OpenAI discovery validation failed.');
    return result;
  }

  Future<Map<String, dynamic>> jwks() async {
    final configuration = await discovery();
    final uri = Uri.parse(configuration['jwks_uri'] as String);
    if (uri.host != 'auth.openai.com') throw const ConnectionFailure('Unexpected identity key address.');
    return json('GET', uri);
  }

  Stream<String> infer(String accessToken, String model, List<Map<String, dynamic>> input) async* {
    final client = _createClient()..connectionTimeout = const Duration(seconds: 20);
    _streamClient = client;
    try {
      final response = await _request('POST', Uri.parse('$resource/responses'), client: client,
        headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json',
          'Accept': 'text/event-stream'},
        body: jsonEncode({'model': model, 'input': input, 'store': false, 'stream': true}));
      if (response.statusCode != 200) {
        final text = await utf8.decoder.bind(response).join().timeout(const Duration(seconds: 30));
        Object? body;
        try { body = jsonDecode(text); } catch (_) { body = null; }
        throw serviceFailure(response.statusCode, body, response.headers.value('x-request-id'));
      }
      if (response.headers.contentType?.mimeType != 'text/event-stream') {
        throw const ConnectionFailure('OpenAI did not open a Responses event stream.');
      }
      yield* responseText(utf8.decoder.bind(response.timeout(const Duration(seconds: 90)))
          .transform(const LineSplitter()));
    } finally {
      client.close(force: true);
      if (identical(_streamClient, client)) _streamClient = null;
    }
  }

  void cancelInference() { _streamClient?.close(force: true); _streamClient = null; }
  void close() { cancelInference(); _client.close(force: true); }
}
