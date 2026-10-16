import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistence groundwork only. This class does not authenticate an account.
/// A future OAuth boundary must validate ID-token signature/claims and granted
/// scopes before calling [ChatGptCredentialStore.write].
class ChatGptCredentials {
  const ChatGptCredentials({
    required this.clientId,
    required this.accessToken,
    required this.refreshToken,
  });

  final String clientId;
  final String accessToken;
  final String refreshToken;

  @override
  String toString() => 'ChatGptCredentials(<redacted>)';
}

class CredentialStorageException implements Exception {
  const CredentialStorageException();

  @override
  String toString() => 'Secure credential storage is unavailable. Sign in again '
      'only after secure storage is available.';
}

/// Stores each issued registration separately using platform secure storage.
/// There is no plaintext fallback and no production caller before eligibility.
class ChatGptCredentialStore {
  const ChatGptCredentialStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  String _key(String clientId) {
    if (clientId.trim().isEmpty || clientId == 'dynamic_agent_client') {
      throw ArgumentError('An issued client ID is required.');
    }
    return 'chatgpt.registration.v1.${base64Url.encode(utf8.encode(clientId))}';
  }

  Future<void> write(ChatGptCredentials credentials) async {
    final key = _key(credentials.clientId);
    if (credentials.accessToken.isEmpty || credentials.refreshToken.isEmpty) {
      throw ArgumentError('Both OAuth tokens are required.');
    }
    try {
      // One record keeps the access/refresh pair together during rotation.
      await _storage.write(
        key: key,
        value: jsonEncode({
          'client_id': credentials.clientId,
          'access_token': credentials.accessToken,
          'refresh_token': credentials.refreshToken,
        }),
      );
    } on PlatformException {
      throw const CredentialStorageException();
    }
  }

  Future<ChatGptCredentials?> read(String clientId) async {
    final key = _key(clientId);
    try {
      final value = await _storage.read(key: key);
      if (value == null) return null;
      final record = jsonDecode(value);
      if (record is! Map<String, dynamic> ||
          record['client_id'] != clientId ||
          record['access_token'] is! String ||
          (record['access_token'] as String).isEmpty ||
          record['refresh_token'] is! String ||
          (record['refresh_token'] as String).isEmpty) {
        throw const CredentialStorageException();
      }
      return ChatGptCredentials(
        clientId: clientId,
        accessToken: record['access_token'] as String,
        refreshToken: record['refresh_token'] as String,
      );
    } on PlatformException {
      throw const CredentialStorageException();
    } on FormatException {
      throw const CredentialStorageException();
    }
  }

  /// Local deletion only; future sign-out must also revoke the OAuth session.
  Future<void> delete(String clientId) async {
    final key = _key(clientId);
    try {
      await _storage.delete(key: key);
    } on PlatformException {
      throw const CredentialStorageException();
    }
  }
}
