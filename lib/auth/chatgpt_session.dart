import 'dart:async';
import 'dart:io';

import 'openai_transport.dart';
import 'protocol.dart';
import 'session_vault.dart';

typedef BrowserOpener = Future<void> Function(Uri uri);

class ChatGptSession {
  ChatGptSession({SessionVault? vault, OpenAiTransport? transport})
    : vault = vault ?? SessionVault(),
      transport = transport ?? OpenAiTransport();
  final SessionVault vault;
  final OpenAiTransport transport;
  Map<String, dynamic>? _record;
  Map<String, dynamic>? active;
  Future<void>? _refresh;
  int _requestGeneration = 0;
  int _authorizationGeneration = 0;
  bool requestsPaused = false;
  String? _pendingIssuedClientId;
  HttpServer? _callback;
  Completer<Uri>? _authorization;
  List<Map<String, dynamic>> models = [];
  // Memory-only, reset on account change and every launch. Never asserts that
  // an external ChatGPT setting was independently inspected by this client.
  bool allowanceOnlyConfirmed = false;

  List<Map<String, dynamic>> get accounts =>
      ((_record?['accounts'] ?? []) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
  bool get planEnabled =>
      active?['access_token'] is String &&
      (active?['scopes'] as List? ?? []).contains(planScope);

  Future<void> load() async {
    _record = await vault.read();
  }

  Future<void> _saveAccount(Map<String, dynamic> account) async {
    final nextAccounts =
        accounts.where((a) => a['client_id'] != account['client_id']).toList()
          ..add(account);
    final next = <String, dynamic>{..._record!, 'accounts': nextAccounts};
    try {
      await vault.write(
        next,
      ); // Only activate after durable credential rotation.
    } catch (_) {
      active = null;
      models = [];
      allowanceOnlyConfirmed = false;
      rethrow;
    }
    _record = next;
    active = account;
  }

  void select(String? clientId) {
    cancelInference();
    _pendingIssuedClientId = null;
    requestsPaused = false;
    models = [];
    allowanceOnlyConfirmed = false;
    active = clientId == null
        ? null
        : accounts.firstWhere((a) => a['client_id'] == clientId);
  }

  Future<void> signIn(BrowserOpener openBrowser, {bool requestPlanConsent = false}) async {
    if (_authorization != null) {
      throw const ConnectionFailure('A sign-in is already open.');
    }
    _record ??= await vault.read();
    final generation = ++_authorizationGeneration;
    final previous = active;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    if (generation != _authorizationGeneration) {
      await server.close(force: true);
      throw const ConnectionFailure('Sign-in cancelled.');
    }
    _callback = server;
    final redirect = Uri.parse('http://127.0.0.1:${server.port}/auth/callback');
    final attempt = AuthorizationAttempt(
      redirect: redirect,
      hostId: _record!['host_id'] as String,
      clientId: previous?['client_id'] as String? ?? _pendingIssuedClientId,
      idTokenHint: previous?['id_token'] as String?,
      requestPlanConsent: requestPlanConsent,
    );
    final callback = Completer<Uri>();
    _authorization = callback;
    // Attach before opening browser. Invalid/unsolicited requests cannot consume
    // the attempt or cause a token exchange. A valid OAuth denial does consume it.
    final subscription = server.listen((request) async {
      request.response.headers.set('Cache-Control', 'no-store');
      request.response.headers.set(
        'Content-Security-Policy',
        "default-src 'none'",
      );
      request.response.headers.set('Referrer-Policy', 'no-referrer');
      final uri = redirect.replace(query: request.uri.query);
      final valid =
          request.method == 'GET' &&
          request.uri.path == redirect.path &&
          request.headers.value(HttpHeaders.hostHeader) ==
              '127.0.0.1:${server.port}' &&
          request.uri.queryParametersAll['state']?.length == 1 &&
          request.uri.queryParameters['state'] == attempt.state;
      if (!valid || callback.isCompleted) {
        request.response.statusCode = 400;
        request.response.write(
          'Invalid callback. Return to the app to restart sign-in.',
        );
      } else {
        callback.complete(uri);
        request.response.write(
          'Sign-in received. Return to Personal Execution App.',
        );
      }
      await request.response.close();
    });
    try {
      // Install a handler before browser launch, including cancellation failures.
      final received = callback.future.timeout(const Duration(minutes: 5));
      final flow = received.then((uri) => attempt.validateCallback(uri));
      // Prevent an unhandled error if browser opening fails before flow is awaited.
      unawaited(flow.then<void>((_) {}, onError: (Object _, StackTrace _) {}));
      await openBrowser(attempt.authorizationUri);
      final result = await flow;
      if (previous == null) _pendingIssuedClientId = result.clientId;
      final tokens = await transport.json(
        'POST',
        Uri.parse('$issuer/api/accounts/oauth/token'),
        form: {
          'grant_type': 'authorization_code',
          'client_id': result.clientId,
          'code': result.code,
          'code_verifier': attempt.verifier,
          'redirect_uri': redirect.toString(),
          'resource': resource,
        },
      );
      final identity = await validateIdToken(
        tokens['id_token'] as String,
        await transport.jwks(),
        result.clientId,
        nonce: attempt.nonce,
        subject: previous?['subject'] as String?,
      );
      final account = _tokenRecord(tokens, result.clientId, identity);
      if (previous?['welcomed'] == true) account['welcomed'] = true;
      if (generation != _authorizationGeneration) {
        throw const ConnectionFailure('Sign-in cancelled before activation.');
      }
      await _saveAccount(account);
      _pendingIssuedClientId = null;
      requestsPaused = false;
      models = [];
      allowanceOnlyConfirmed = false;
    } finally {
      if (!callback.isCompleted) {
        callback.complete(redirect); // Discard abandoned attempt.
      }
      _authorization = null;
      _callback = null;
      await subscription.cancel();
      await server.close(force: true);
    }
  }

  Map<String, dynamic> _tokenRecord(
    Map<String, dynamic> tokens,
    String clientId,
    Map<String, dynamic> identity, {
    Map<String, dynamic>? previous,
  }) {
    final scope = tokens['scope'];
    final scopes = scope is String
        ? scope.split(RegExp(r'\s+'))
        : previous?['scopes'];
    if (tokens['token_type']?.toString().toLowerCase() != 'bearer' ||
        tokens['access_token'] is! String ||
        (tokens['access_token'] as String).isEmpty ||
        tokens['refresh_token'] is! String ||
        (tokens['refresh_token'] as String).isEmpty ||
        tokens['expires_in'] is! num ||
        (tokens['expires_in'] as num) <= 0 ||
        scopes is! List) {
      throw const ConnectionFailure(
        'OpenAI returned an incomplete credential set. Reconnect.',
      );
    }
    return {
      'client_id': clientId,
      'subject': identity['sub'],
      'email': identity['email'],
      'id_token': tokens['id_token'] ?? previous?['id_token'],
      'access_token': tokens['access_token'],
      'refresh_token': tokens['refresh_token'],
      'expires_at':
          DateTime.now().millisecondsSinceEpoch +
          (tokens['expires_in'] as num).toInt() * 1000,
      'scopes': scopes,
      if (previous?['welcomed'] == true) 'welcomed': true,
    };
  }

  Future<void> acknowledgeWelcome() async {
    if (active == null) return;
    await _saveAccount({...active!, 'welcomed': true});
  }

  Future<String> accessToken() async {
    if (!planEnabled) {
      throw const ConnectionFailure(
        'Enable ChatGPT plan permission by reconnecting before inference.',
      );
    }
    if ((active!['expires_at'] as int? ?? 0) <=
        DateTime.now().millisecondsSinceEpoch + 60000) {
      _refresh ??= _refreshTokens();
      try {
        await _refresh;
      } finally {
        _refresh = null;
      }
    }
    if (!planEnabled) {
      throw const ConnectionFailure(
        'ChatGPT plan permission is no longer enabled. Reconnect.',
      );
    }
    return active!['access_token'] as String;
  }

  Future<void> _refreshTokens() async {
    final current = active!;
    try {
      final tokens = await transport.json(
        'POST',
        Uri.parse('$issuer/api/accounts/oauth/token'),
        form: {
          'grant_type': 'refresh_token',
          'client_id': current['client_id'] as String,
          'refresh_token': current['refresh_token'] as String,
          'resource': resource,
        },
      );
      final identity = tokens['id_token'] == null
          ? <String, dynamic>{
              'sub': current['subject'],
              'email': current['email'],
            }
          : await validateIdToken(
              tokens['id_token'] as String,
              await transport.jwks(),
              current['client_id'] as String,
              subject: current['subject'] as String,
            );
      await _saveAccount(
        _tokenRecord(
          tokens,
          current['client_id'] as String,
          identity,
          previous: current,
        ),
      );
    } on ConnectionFailure catch (error) {
      if ([
        'invalid_grant',
        'invalid_refresh_token',
        'token_expired',
        'refresh_token_expired',
        'refresh_token_invalidated',
        'refresh_token_reused',
      ].contains(error.code)) {
        await _clearTokens(current);
      }
      rethrow;
    }
  }

  Future<void> discoverModels() async {
    models = [];
    final result = await transport.json(
      'GET',
      Uri.parse('$resource/models'),
      headers: {'Authorization': 'Bearer ${await accessToken()}'},
    );
    if (result['models'] is! List) {
      throw const ConnectionFailure(
        'The account model catalog was unexpected.',
      );
    }
    models = (result['models'] as List)
        .whereType<Map<String, dynamic>>()
        .where(
          (m) =>
              m['visibility'] == 'list' &&
              m['slug'] is String &&
              m['display_name'] is String,
        )
        .toList();
    if (models.isEmpty) {
      throw const ConnectionFailure(
        'No eligible models are available to this account.',
      );
    }
    requestsPaused = false;
  }

  Stream<String> infer(
    String model,
    List<Map<String, dynamic>> history,
  ) async* {
    if (!allowanceOnlyConfirmed) {
      throw const ConnectionFailure(
        'Confirm allowance-only settings before sending.',
      );
    }
    if (!models.any((m) => m['slug'] == model)) {
      throw const ConnectionFailure(
        'Refresh models and select an available model.',
      );
    }
    if (requestsPaused) {
      throw const ConnectionFailure(
        'Requests are paused. Check Manage usage, then explicitly refresh models before trying again.',
      );
    }
    final generation = _requestGeneration;
    final token = await accessToken();
    if (generation != _requestGeneration) {
      throw const ConnectionFailure('Request stopped before sending.');
    }
    try {
      yield* transport.infer(token, model, history);
    } on ConnectionFailure catch (error) {
      if (error.status == 401 ||
          error.status == 403 ||
          error.status == 429 ||
          [
            'subscription_sharing_usage_limit_exceeded',
            'subscription_sharing_user_not_eligible',
          ].contains(error.code)) {
        requestsPaused = true;
      }
      rethrow;
    }
  }

  Future<void> _clearTokens(Map<String, dynamic> current) async {
    final account = Map<String, dynamic>.from(current)
      ..remove('access_token')
      ..remove('refresh_token')
      ..remove('id_token')
      ..remove('expires_at');
    // If secure deletion fails, don't continue using in-memory credentials.
    active = null;
    models = [];
    allowanceOnlyConfirmed = false;
    await _saveAccount(account);
  }

  Future<bool> signOut() async {
    cancelInference();
    cancelSignIn();
    final current = active;
    if (current == null) return true;
    var revoked = current['refresh_token'] == null;
    if (!revoked) {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final configuration = await transport.discovery();
          final endpoint = Uri.parse(
            configuration['revocation_endpoint'] as String,
          );
          if (endpoint.host != 'auth.openai.com') {
            throw const ConnectionFailure('Unexpected revocation address.');
          }
          await transport.json(
            'POST',
            endpoint,
            form: {
              'token': current['refresh_token'] as String,
              'token_type_hint': 'refresh_token',
              'client_id': current['client_id'] as String,
            },
          );
          revoked = true;
          break;
        } catch (_) {
          if (attempt == 0) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          }
        }
      }
    }
    await _clearTokens(current);
    return revoked;
  }

  void cancelInference() {
    _requestGeneration++;
    transport.cancelInference();
  }

  void cancelSignIn() {
    _authorizationGeneration++;
    final callback = _authorization;
    if (callback != null && !callback.isCompleted) {
      callback.completeError(const ConnectionFailure('Sign-in cancelled.'));
    }
    unawaited(_callback?.close(force: true));
  }

  void dispose() {
    cancelSignIn();
    cancelInference();
    transport.close();
  }
}
