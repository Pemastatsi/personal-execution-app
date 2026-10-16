import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jose/jose.dart';
import 'package:personal_execution_app/auth/protocol.dart';

void main() {
  test('PKCE matches RFC 7636 and each attempt has independent secrets', () {
    final attempt = AuthorizationAttempt(redirect: Uri.parse('http://127.0.0.1:1455/auth/callback'), hostId: newHostId());
    final uri = attempt.authorizationUri.queryParameters;
    expect(uri['client_id'], 'dynamic_agent_client');
    expect(uri['resource'], resource);
    expect(uri['scope'], contains(planScope));
    expect(uri['code_challenge_method'], 'S256');
    expect(uri['code_challenge'], base64Url.encode(sha256.convert(ascii.encode(attempt.verifier)).bytes).replaceAll('=', ''));
    expect(attempt.verifier.length, inInclusiveRange(43, 128));
    final other = AuthorizationAttempt(redirect: attempt.redirect, hostId: attempt.hostId);
    expect(other.state, isNot(attempt.state));
    expect(other.nonce, isNot(attempt.nonce));
    expect(other.verifier, isNot(attempt.verifier));
    const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
    expect(base64Url.encode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', ''),
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM');
  });

  test('callback rejects wrong state, host, path, duplicates, denial and changed client', () {
    final a = AuthorizationAttempt(redirect: Uri.parse('http://127.0.0.1:1234/auth/callback'), hostId: newHostId(), clientId: 'issued');
    Uri callback(Map<String, String> query) => a.redirect.replace(queryParameters: {'state': a.state, 'code': 'code', ...query});
    expect(a.validateCallback(callback({})), (clientId: 'issued', code: 'code'));
    for (final uri in [callback({'state': 'wrong'}), callback({'client_id': 'other'}),
      callback({'error': 'access_denied'}), callback({}).replace(host: 'localhost'),
      callback({}).replace(path: '/callback'), callback({}).replace(query: 'state=${a.state}&state=${a.state}&code=code')]) {
      expect(() => a.validateCallback(uri), throwsA(isA<ConnectionFailure>()));
    }
    final fresh = AuthorizationAttempt(redirect: a.redirect, hostId: a.hostId);
    expect(() => fresh.validateCallback(fresh.redirect.replace(queryParameters: {'state': fresh.state, 'code': 'a'})),
      throwsA(isA<ConnectionFailure>()));
  });

  group('signed ID token validation', () {
    late JsonWebKey key;
    late Map<String, dynamic> keys;
    final now = DateTime.utc(2026, 10, 16);
    final claims = <String, dynamic>{'iss': issuer, 'aud': 'issued', 'sub': 'account', 'nonce': 'nonce',
      'exp': now.millisecondsSinceEpoch ~/ 1000 + 3600};
    String sign(Map<String, dynamic> c, {JsonWebKey? signingKey, String algorithm = 'RS256'}) {
      final builder = JsonWebSignatureBuilder()..jsonContent = c;
      builder.setProtectedHeader('kid', 'test-key');
      builder.addRecipient(signingKey ?? key, algorithm: algorithm);
      return builder.build().toCompactSerialization();
    }
    setUpAll(() {
      key = JsonWebKey.generate('RS256', keyBitLength: 2048);
      final jwk = key.toJson();
      keys = {'keys': [{'kty': 'RSA', 'kid': 'test-key', 'n': jwk['n'], 'e': jwk['e'], 'use': 'sig', 'alg': 'RS256'}]};
    });
    test('accepts a verified signature and bound identity', () async {
      expect((await validateIdToken(sign(claims), keys, 'issued', nonce: 'nonce', now: now))['sub'], 'account');
    });
    test('rejects forged signatures, bad claims and algorithm confusion', () async {
      for (final c in [
        {...claims, 'iss': 'https://attacker.invalid'}, {...claims, 'aud': 'other'},
        {...claims, 'exp': 0}, {...claims, 'nonce': 'wrong'}, {...claims, 'sub': ''},
        {...claims, 'aud': ['issued', 'other']}, {...claims, 'azp': 'other'},
      ]) {
        await expectLater(validateIdToken(sign(c), keys, 'issued', nonce: 'nonce', now: now), throwsA(isA<ConnectionFailure>()));
      }
      await expectLater(validateIdToken(sign(claims, signingKey: JsonWebKey.generate('RS256')), keys, 'issued', now: now), throwsA(isA<ConnectionFailure>()));
      final unsigned = '${base64Url.encode(utf8.encode('{"alg":"none","kid":"test-key"}'))}.${base64Url.encode(utf8.encode(jsonEncode(claims)))}.';
      await expectLater(validateIdToken(unsigned, keys, 'issued', now: now), throwsA(isA<ConnectionFailure>()));
      await expectLater(validateIdToken(sign(claims), keys, 'issued', subject: 'different', now: now), throwsA(isA<ConnectionFailure>()));
    });
  });

  Stream<String> lines(List<Map<String, dynamic>> events) => Stream.fromIterable([
    ':keepalive', '', for (final event in events) ...['data: ${jsonEncode(event)}', ''],
  ]);
  test('stream handles deltas and requires successful completion', () async {
    final result = await responseText(lines([
      {'type': 'response.output_text.delta', 'delta': 'Hello'},
      {'type': 'response.output_text.delta', 'delta': ', world!'},
      {'type': 'response.completed', 'response': {'status': 'completed'}},
    ])).join();
    expect(result, 'Hello, world!');
    await expectLater(responseText(lines([{'type': 'response.output_text.delta', 'delta': 'partial'}])).drain<void>(),
      throwsA(isA<ConnectionFailure>()));
  });
  test('usage failure after partial output, incomplete and malformed streams fail', () async {
    for (final terminal in [
      {'type': 'response.failed', 'response': {'error': {'code': 'subscription_sharing_usage_limit_exceeded'}}},
      {'type': 'response.incomplete'}, {'type': 'error', 'code': 'subscription_sharing_usage_unavailable'},
      {'type': 'response.completed', 'response': {'status': 'failed'}},
    ]) {
      await expectLater(responseText(lines([{'type': 'response.output_text.delta', 'delta': 'partial'}, terminal])).drain<void>(),
        throwsA(isA<ConnectionFailure>()));
    }
    await expectLater(responseText(Stream.fromIterable(['data: invalid', ''])).drain<void>(), throwsA(isA<ConnectionFailure>()));
  });
  test('admission errors handle detail-only bodies and redact server text', () {
    for (final status in [401, 403, 429, 503]) {
      final error = serviceFailure(status, {'detail': 'private-account-data'}, 'request-123');
      expect(error.status, status);
      expect(error.toString(), isNot(contains('private-account-data')));
      expect(error.requestId, 'request-123');
    }
    expect(serviceFailure(403, {'error': {'code': 'subscription_sharing_user_not_eligible'}}, null).message, contains('not eligible'));
  });
}
