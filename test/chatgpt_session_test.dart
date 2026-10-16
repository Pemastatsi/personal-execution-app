import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jose/jose.dart';
import 'package:personal_execution_app/auth/chatgpt_session.dart';
import 'package:personal_execution_app/auth/openai_transport.dart';
import 'package:personal_execution_app/auth/protocol.dart';
import 'package:personal_execution_app/auth/session_vault.dart';

class FakeOpenAi extends OpenAiTransport {
  final key = JsonWebKey.generate('RS256');
  String nonce = '';
  String scopes = requestedScopes;
  int lifetime = 3600;
  int refreshes = 0;
  int inferences = 0;
  bool invalidGrant = false;
  Map<String, String>? exchange;
  @override
  Future<Map<String, dynamic>> jwks() async {
    final jwk = key.toJson();
    return {'keys': [{'kty': 'RSA', 'kid': 'test-key', 'n': jwk['n'], 'e': jwk['e']}]};
  }
  @override
  Future<Map<String, dynamic>> json(String method, Uri uri, {
    Map<String, String> headers = const {}, Map<String, String>? form,
  }) async {
    if (uri.path.endsWith('/models')) {
      return {'models': [{'slug': 'eligible', 'display_name': 'Eligible test model', 'visibility': 'list'},
        {'slug': 'hidden', 'display_name': 'Hidden', 'visibility': 'hide'}]};
    }
    exchange = form;
    final refresh = form?['grant_type'] == 'refresh_token';
    if (refresh) {
      refreshes++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      if (invalidGrant) throw serviceFailure(400, {'error': 'invalid_grant'}, null);
    }
    final builder = JsonWebSignatureBuilder()..jsonContent = {
      'iss': issuer, 'aud': 'issued-client', 'sub': 'test-account', 'email': 'test@example.invalid',
      'nonce': nonce, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    };
    builder.setProtectedHeader('kid', 'test-key');
    builder.addRecipient(key, algorithm: 'RS256');
    return {'access_token': refresh ? 'rotated-access' : 'initial-access',
      'refresh_token': refresh ? 'rotated-refresh' : 'initial-refresh',
      'id_token': builder.build().toCompactSerialization(), 'scope': scopes,
      'token_type': 'Bearer', 'expires_in': refresh ? 3600 : lifetime};
  }
  @override
  Stream<String> infer(String accessToken, String model, List<Map<String, dynamic>> input) async* {
    inferences++;
    yield 'Hello, world!';
  }
}

Future<void> signInFixture(ChatGptSession session, FakeOpenAi server) => session.signIn((uri) async {
  server.nonce = uri.queryParameters['nonce']!;
  final redirect = Uri.parse(uri.queryParameters['redirect_uri']!);
  final client = HttpClient();
  try {
    // Unsolicited state must not consume the pending attempt.
    var response = await (await client.getUrl(redirect.replace(queryParameters: {'state': 'wrong', 'code': 'bad'}))).close();
    expect(response.statusCode, 400);
    await response.drain<void>();
    response = await (await client.getUrl(redirect.replace(queryParameters: {
      'state': uri.queryParameters['state']!, 'code': 'fixture-code', 'client_id': 'issued-client',
    }))).close();
    expect(response.statusCode, 200);
    await response.drain<void>();
  } finally { client.close(force: true); }
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('loopback OAuth fixture binds exchange, identity, scopes, catalog and secure resume', () async {
    final api = FakeOpenAi();
    final session = ChatGptSession(transport: api);
    addTearDown(session.dispose);
    await session.load();
    final host = (await session.vault.read())['host_id'];
    await signInFixture(session, api);
    expect(api.exchange!['client_id'], 'issued-client');
    expect(api.exchange!['resource'], resource);
    expect(api.exchange!['redirect_uri'], startsWith('http://127.0.0.1:'));
    expect(api.exchange!['code_verifier'], isNotEmpty);
    expect(session.planEnabled, isTrue);
    await session.discoverModels();
    expect(session.models.map((m) => m['slug']), ['eligible']);
    await expectLater(session.infer('eligible', []).drain<void>(), throwsA(isA<ConnectionFailure>()));
    expect(api.inferences, 0); // Credit-settings gate applies before network inference.
    session.allowanceOnlyConfirmed = true;
    expect(await session.infer('eligible', [{'role': 'user', 'content': 'Hello'}]).join(), 'Hello, world!');
    final reopened = ChatGptSession(transport: api);
    addTearDown(reopened.dispose);
    await reopened.load();
    reopened.select('issued-client');
    expect((await reopened.vault.read())['host_id'], host);
    expect(reopened.active!['subject'], 'test-account');
    expect(reopened.allowanceOnlyConfirmed, isFalse);
  });
  test('missing plan permission never enables models or inference', () async {
    final api = FakeOpenAi()..scopes = 'openid profile email offline_access';
    final session = ChatGptSession(transport: api);
    addTearDown(session.dispose);
    await signInFixture(session, api);
    expect(session.planEnabled, isFalse);
    await expectLater(session.discoverModels(), throwsA(isA<ConnectionFailure>()));
    expect(api.inferences, 0);
  });
  test('concurrent expiry checks serialize refresh and persist rotated pair', () async {
    final api = FakeOpenAi()..lifetime = 1;
    final session = ChatGptSession(transport: api);
    addTearDown(session.dispose);
    await signInFixture(session, api);
    expect(await Future.wait([session.accessToken(), session.accessToken(), session.accessToken()]),
      everyElement('rotated-access'));
    expect(api.refreshes, 1);
    expect(api.exchange!['scope'], isNull);
    final record = await SessionVault().read();
    expect((record['accounts'] as List).single['refresh_token'], 'rotated-refresh');
  });
  test('revoked refresh stops access and preserves the registration mapping', () async {
    final api = FakeOpenAi()..lifetime = 1;
    final session = ChatGptSession(transport: api);
    addTearDown(session.dispose);
    await signInFixture(session, api);
    api.invalidGrant = true;
    await expectLater(session.accessToken(), throwsA(isA<ConnectionFailure>()));
    expect(session.planEnabled, isFalse);
    expect(session.active!['client_id'], 'issued-client');
    expect(session.active!['refresh_token'], isNull);
  });
  test('cancel closes the loopback attempt without exchanging a code', () async {
    final api = FakeOpenAi();
    final session = ChatGptSession(transport: api);
    addTearDown(session.dispose);
    await expectLater(session.signIn((_) async { session.cancelSignIn(); }), throwsA(isA<ConnectionFailure>()));
    expect(api.exchange, isNull);
  });
  test('stop during refresh prevents a late inference request', () async {
    final api = FakeOpenAi()..lifetime = 1;
    final session = ChatGptSession(transport: api);
    addTearDown(session.dispose);
    await signInFixture(session, api);
    session.models = [{'slug': 'eligible'}];
    session.allowanceOnlyConfirmed = true;
    final request = session.infer('eligible', []).drain<void>();
    await Future<void>.delayed(const Duration(milliseconds: 2));
    session.cancelInference();
    await expectLater(request, throwsA(isA<ConnectionFailure>()));
    expect(api.inferences, 0);
  });

}
