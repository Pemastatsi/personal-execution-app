import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_execution_app/auth/openai_transport.dart';
import 'package:personal_execution_app/auth/protocol.dart';

class FakeHeaders implements HttpHeaders {
  final values = <String, String>{};
  ContentType? type;
  @override
  ContentType? get contentType => type;
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) { values[name] = value.toString(); }
  @override
  String? value(String name) => values[name];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  FakeResponse(this.statusCode, String body, {String mime = 'text/event-stream'})
      : chunks = utf8.encode(body) {
    headers.type = ContentType.parse(mime);
  }
  final List<int> chunks;
  @override
  final int statusCode;
  @override
  final headers = FakeHeaders();
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData, {
    Function? onError, void Function()? onDone, bool? cancelOnError,
  }) => Stream.fromIterable(chunks.map((b) => [b])).listen(onData,
      onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class FakeRequest implements HttpClientRequest {
  FakeRequest(this.response);
  final FakeResponse response;
  final body = StringBuffer();
  @override
  bool followRedirects = true;
  @override
  final headers = FakeHeaders();
  @override
  void write(Object? object) { body.write(object); }
  @override
  Future<HttpClientResponse> close() async => response;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class FakeClient implements HttpClient {
  FakeClient(this.response);
  final FakeResponse response;
  late FakeRequest request;
  Uri? requestedUri;
  String? requestedMethod;
  bool closed = false;
  @override
  Duration? connectionTimeout;
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    requestedMethod = method;
    requestedUri = url;
    return request = FakeRequest(response);
  }
  @override
  void close({bool force = false}) { closed = true; }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
void main() {
  test('subscription Responses wire contract streams UTF-8, no redirect or fallback', () async {
    final client = FakeClient(FakeResponse(200,
      'data: {"type":"response.output_text.delta","delta":"Hello 🌍"}\r\n\r\n'
      'data: {"type":"response.completed","response":{"status":"completed"}}\n\n'));
    final transport = OpenAiTransport(clientFactory: () => client);
    addTearDown(transport.close);
    final history = <Map<String, dynamic>>[{'role': 'user', 'content': [
      {'type': 'input_text', 'text': 'Describe this screenshot'},
      {'type': 'input_image', 'image_url': 'data:image/png;base64,FAKE'},
    ]}];
    expect(await transport.infer('fixture-oauth-token', 'discovered-slug', history).join(), 'Hello 🌍');
    expect(client.requestedUri.toString(), '$resource/responses');
    expect(client.requestedMethod, 'POST');
    expect(client.request.followRedirects, isFalse);
    expect(client.request.headers.values['Authorization'], 'Bearer fixture-oauth-token');
    expect(jsonDecode(client.request.body.toString()), {
      'model': 'discovered-slug', 'input': history, 'store': false, 'stream': true,
    });
    expect(client.closed, isTrue);
  });
  test('redirect admission fails without another route or exposing body', () async {
    var requests = 0;
    final client = FakeClient(FakeResponse(302, '{"detail":"private-account-info"}', mime: 'application/json'));
    final transport = OpenAiTransport(clientFactory: () { requests++; return client; });
    addTearDown(transport.close);
    await expectLater(transport.infer('fixture-token', 'model', []).drain<void>(),
      throwsA(isA<ConnectionFailure>().having((e) => e.status, 'status', 302)
        .having((e) => e.toString(), 'redacted', isNot(contains('private-account-info')))));
    expect(requests, 2); // Persistent JSON client plus exactly one inference client.
    expect(client.request.followRedirects, isFalse);
  });
}
