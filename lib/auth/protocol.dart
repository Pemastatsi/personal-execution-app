import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:jose/jose.dart';

const issuer = 'https://auth.openai.com';
const resource = 'https://api.openai.com/v1';
const planScope = 'chatgpt.tokens.use.direct';
const requestedScopes =
    'openid profile email offline_access resource.invoke $planScope';

class ConnectionFailure implements Exception {
  const ConnectionFailure(
    this.message, {
    this.status,
    this.code,
    this.requestId,
  });
  final String message;
  final int? status;
  final String? code;
  final String? requestId;
  @override
  String toString() => message;
}

String randomUrlToken([int length = 32]) => base64Url
    .encode(List.generate(length, (_) => Random.secure().nextInt(256)))
    .replaceAll('=', '');

String newHostId() {
  final bytes = List.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return 'urn:uuid:${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class AuthorizationAttempt {
  AuthorizationAttempt({
    required this.redirect,
    required this.hostId,
    this.clientId,
    this.idTokenHint,
    this.requestPlanConsent = false,
  }) : state = randomUrlToken(),
       nonce = randomUrlToken(),
       verifier = randomUrlToken(48);
  final Uri redirect;
  final String hostId;
  final String? clientId;
  final String? idTokenHint;
  final bool requestPlanConsent;
  final String state;
  final String nonce;
  final String verifier;

  Uri get authorizationUri =>
      Uri.parse('$issuer/api/accounts/authorize').replace(
        queryParameters: {
          'client_id': clientId ?? 'dynamic_agent_client',
          if (clientId == null) 'agent_name_hint': 'Personal Execution App',
          'ext_agent_host_id': hostId,
          'id_token_hint': ?idTokenHint,
          if (requestPlanConsent) 'prompt': 'consent',
          'response_type': 'code',
          'redirect_uri': redirect.toString(),
          'scope': requestedScopes,
          'resource': resource,
          'state': state,
          'nonce': nonce,
          'code_challenge_method': 'S256',
          'code_challenge': base64Url
              .encode(sha256.convert(ascii.encode(verifier)).bytes)
              .replaceAll('=', ''),
        },
      );

  ({String clientId, String code}) validateCallback(Uri callback) {
    if (callback.scheme != redirect.scheme ||
        callback.host != redirect.host ||
        callback.port != redirect.port ||
        callback.path != redirect.path ||
        callback.queryParametersAll.values.any((v) => v.length != 1) ||
        callback.queryParameters['state'] != state) {
      throw const ConnectionFailure(
        'Sign-in callback validation failed. Start again.',
      );
    }
    final query = callback.queryParameters;
    if (query.containsKey('error')) {
      throw ConnectionFailure(
        query['error'] == 'access_denied'
            ? 'Sign-in or plan permission was declined.'
            : 'OpenAI could not finish sign-in.',
      );
    }
    final issued = query['client_id'] ?? clientId;
    if (issued == null ||
        issued.isEmpty ||
        issued == 'dynamic_agent_client' ||
        (clientId != null && issued != clientId) ||
        (query['code'] ?? '').isEmpty) {
      throw const ConnectionFailure(
        'Registration is incomplete or changed. Start again.',
      );
    }
    return (clientId: issued, code: query['code']!);
  }

  @override
  String toString() => 'AuthorizationAttempt(<redacted>)';
}

/// Only RS256 and locally supplied keys from the pinned OpenAI discovery host.
/// Remote jku/x5u headers never select a key source.
Future<Map<String, dynamic>> validateIdToken(
  String token,
  Map<String, dynamic> jwks,
  String clientId, {
  String? nonce,
  String? subject,
  DateTime? now,
}) async {
  try {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException();
    }
    final header =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))))
            as Map<String, dynamic>;
    if (header['alg'] != 'RS256' ||
        header['kid'] is! String ||
        header.containsKey('crit')) {
      throw const FormatException();
    }
    final keys = (jwks['keys'] as List)
        .whereType<Map<String, dynamic>>()
        .where(
          (key) =>
              key['kid'] == header['kid'] &&
              key['kty'] == 'RSA' &&
              (key['use'] == null || key['use'] == 'sig') &&
              (key['alg'] == null || key['alg'] == 'RS256'),
        )
        .toList();
    if (keys.length != 1) throw const FormatException();
    final keyStore = JsonWebKeyStore()
      ..addKey(JsonWebKey.fromJson(keys.single));
    final jwt = JsonWebSignature.fromCompactSerialization(token);
    if (!await jwt.verify(keyStore)) throw const FormatException();
    final claims = jwt.unverifiedPayload.jsonContent as Map<String, dynamic>;
    final seconds = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final audience = claims['aud'];
    if (claims['iss'] != issuer ||
        !(audience == clientId ||
            (audience is List && audience.contains(clientId))) ||
        (audience is List &&
            audience.length > 1 &&
            claims['azp'] != clientId) ||
        (claims['azp'] != null && claims['azp'] != clientId) ||
        claims['exp'] is! num ||
        (claims['exp'] as num) <= seconds ||
        (claims['nbf'] != null && (claims['nbf'] as num) > seconds + 30) ||
        (claims['iat'] != null && (claims['iat'] as num) > seconds + 30) ||
        claims['sub'] is! String ||
        (claims['sub'] as String).isEmpty ||
        (nonce != null && claims['nonce'] != nonce) ||
        (subject != null && claims['sub'] != subject)) {
      throw const FormatException();
    }
    return claims;
  } catch (_) {
    throw const ConnectionFailure(
      'OpenAI identity validation failed. Sign in again.',
    );
  }
}

ConnectionFailure serviceFailure(int status, Object? body, String? requestId) {
  final error = body is Map ? body['error'] : null;
  final code = error is Map
      ? error['code']
      : body is Map
      ? body['error']
      : null;
  final known = code is String ? code : null;
  final message = switch (known) {
    'subscription_sharing_user_not_eligible' =>
      'This account or workspace is not eligible for ChatGPT plan usage.',
    'subscription_sharing_usage_limit_exceeded' =>
      'ChatGPT plan usage limit reached. Check Manage usage and wait for the limit to reset.',
    'subscription_sharing_usage_unavailable' =>
      'ChatGPT usage is temporarily unavailable. Try later.',
    'subscription_sharing_unsupported_capability' =>
      'The selected model or image input is unsupported. Change the input or model before trying again.',
    'subscription_sharing_route_not_supported' =>
      'OpenAI did not permit the documented Responses route for this registration.',
    'chatpass_v2_scope_not_authorized' ||
    'chatpass_v2_invalid_authorization_context' =>
      'This registration does not authorize ChatGPT plan usage. Reconnect or check app eligibility.',
    'subscription_sharing_user_unavailable' =>
      'Account or workspace information is temporarily unavailable. Try later.',
    'invalid_grant' ||
    'invalid_refresh_token' ||
    'token_expired' ||
    'refresh_token_expired' ||
    'refresh_token_reused' ||
    'refresh_token_invalidated' =>
      'The renewable session expired or was revoked. Sign in again.',
    _ => switch (status) {
      401 =>
        'OpenAI did not accept this session or its plan permission. Reconnect.',
      403 => 'OpenAI policy or region restrictions prevented access.',
      429 =>
        'A usage or rate limit was reached. Check Manage usage and try later.',
      503 => 'ChatGPT plan routing is unavailable. Try later.',
      _ => 'OpenAI could not complete this operation. Try later.',
    },
  };
  // Do not expose arbitrary server messages, bodies, or callback values: they
  // can contain account data. Retain bounded machine diagnostics in memory.
  String? safe(String? value) =>
      value != null && RegExp(r'^[a-zA-Z0-9_.-]{1,128}$').hasMatch(value)
      ? value
      : null;
  return ConnectionFailure(
    message,
    status: status,
    code: safe(known),
    requestId: safe(requestId),
  );
}

/// Parses SSE independently of packet boundaries, requiring a completed event.
Stream<String> responseText(Stream<String> lines) async* {
  final data = <String>[];
  var completed = false;
  await for (final line in lines) {
    if (line.isNotEmpty) {
      if (line.startsWith('data:')) data.add(line.substring(5).trimLeft());
      continue;
    }
    if (data.isEmpty) continue;
    final payload = data.join('\n');
    data.clear();
    if (payload == '[DONE]') break;
    Map<String, dynamic> event;
    try {
      event = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      throw const ConnectionFailure('The response stream was malformed.');
    }
    switch (event['type']) {
      case 'response.output_text.delta':
        if (event['delta'] is String) yield event['delta'] as String;
      case 'response.completed':
        final response = event['response'];
        if (response is! Map || response['status'] != 'completed') {
          throw const ConnectionFailure(
            'OpenAI did not confirm a completed response.',
          );
        }
        completed = true;
      case 'response.failed':
        final response = event['response'];
        throw serviceFailure(200, response, null);
      case 'error':
        throw serviceFailure(200, {'error': event}, null);
      case 'response.incomplete':
        throw const ConnectionFailure(
          'The response is incomplete. It was not added to the conversation.',
        );
    }
    if (completed) break;
  }
  if (!completed) {
    throw const ConnectionFailure(
      'The stream stopped before completion. Partial output was not saved.',
    );
  }
}
