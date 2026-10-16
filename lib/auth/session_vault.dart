import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../storage/chatgpt_credential_store.dart';
import 'protocol.dart';

/// Extends PR #1's single-record secure-storage pattern to keep the host,
/// registration identity, and rotating credential set in one encrypted record.
/// The earlier scaffold's v1 records have no verified identity; never import them.
class SessionVault {
  SessionVault({FlutterSecureStorage storage = const FlutterSecureStorage()})
    : _storage = storage;
  final FlutterSecureStorage _storage;
  static const key = 'chatgpt.sessions.v2';

  Future<Map<String, dynamic>> read() async {
    try {
      final value = await _storage.read(key: key);
      if (value == null) {
        final initial = <String, dynamic>{
          'host_id': newHostId(),
          'accounts': <dynamic>[],
        };
        await write(initial);
        return initial;
      }
      final record = jsonDecode(value) as Map<String, dynamic>;
      if (record['host_id'] is! String ||
          record['accounts'] is! List ||
          !RegExp(
            r'^urn:uuid:[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ).hasMatch(record['host_id'] as String)) {
        throw const FormatException();
      }
      for (final account in record['accounts'] as List) {
        if (account is! Map ||
            account['client_id'] is! String ||
            (account['client_id'] as String).isEmpty ||
            account['client_id'] == 'dynamic_agent_client' ||
            account['subject'] is! String ||
            (account['subject'] as String).isEmpty ||
            account['scopes'] is! List ||
            (account['scopes'] as List).any((s) => s is! String)) {
          throw const FormatException();
        }
        final hasTokens = [
          'access_token',
          'refresh_token',
          'id_token',
          'expires_at',
        ].any(account.containsKey);
        if (hasTokens &&
            (account['expires_at'] is! int ||
                ['access_token', 'refresh_token', 'id_token'].any(
                  (k) =>
                      account[k] is! String || (account[k] as String).isEmpty,
                ))) {
          throw const FormatException();
        }
      }
      return record;
    } catch (_) {
      throw const CredentialStorageException();
    }
  }

  Future<void> write(Map<String, dynamic> record) async {
    try {
      await _storage.write(key: key, value: jsonEncode(record));
    } on PlatformException {
      throw const CredentialStorageException();
    } on MissingPluginException {
      throw const CredentialStorageException();
    }
  }
}
