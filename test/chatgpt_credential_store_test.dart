import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_execution_app/storage/chatgpt_credential_store.dart';

class _UnavailableStorage implements FlutterSecureStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw PlatformException(
    code: 'unavailable',
    message: 'fake-private-platform-diagnostic',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const first = ChatGptCredentials(
    clientId: 'test-issued-client-a',
    accessToken: 'fake-access-a',
    refreshToken: 'fake-refresh-a',
  );
  const second = ChatGptCredentials(
    clientId: 'test-issued-client-b',
    accessToken: 'fake-access-b',
    refreshToken: 'fake-refresh-b',
  );

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('platform failures never fall back or expose native diagnostics', () async {
    final store = ChatGptCredentialStore(storage: _UnavailableStorage());
    for (final operation in [
      () => store.read(first.clientId),
      () => store.write(first),
      () => store.delete(first.clientId),
    ]) {
      await expectLater(
        operation(),
        throwsA(
          isA<CredentialStorageException>().having(
            (error) => error.toString(),
            'safe diagnostic',
            isNot(contains('fake-private-platform-diagnostic')),
          ),
        ),
      );
    }
  });

  test('registrations remain separate when tokens rotate or are deleted', () async {
    const store = ChatGptCredentialStore();
    await store.write(first);
    await store.write(second);
    await store.write(
      const ChatGptCredentials(
        clientId: 'test-issued-client-a',
        accessToken: 'fake-access-rotated',
        refreshToken: 'fake-refresh-rotated',
      ),
    );

    // A new boundary instance reads the same secure platform store.
    const reopened = ChatGptCredentialStore();
    final rotated = await reopened.read(first.clientId);
    expect(rotated!.accessToken, 'fake-access-rotated');
    expect(rotated.refreshToken, 'fake-refresh-rotated');
    expect((await reopened.read(second.clientId))!.refreshToken, second.refreshToken);

    await reopened.delete(first.clientId);
    expect(await reopened.read(first.clientId), isNull);
    expect((await reopened.read(second.clientId))!.accessToken, second.accessToken);
  });

  test('refuses bootstrap client ID and empty tokens without saving', () async {
    const store = ChatGptCredentialStore();
    for (final clientId in ['', ' ', 'dynamic_agent_client']) {
      await expectLater(
        store.write(ChatGptCredentials(
          clientId: clientId,
          accessToken: 'fake-access',
          refreshToken: 'fake-refresh',
        )),
        throwsArgumentError,
      );
    }
    for (final tokens in [('', 'fake-refresh'), ('fake-access', '')]) {
      await expectLater(
        store.write(ChatGptCredentials(
          clientId: first.clientId,
          accessToken: tokens.$1,
          refreshToken: tokens.$2,
        )),
        throwsArgumentError,
      );
    }
    expect(await store.read(first.clientId), isNull);
  });

  test('malformed or mismatched credentials fail without leaking data', () async {
    final key = 'chatgpt.registration.v1.'
        '${base64Url.encode(utf8.encode(first.clientId))}';
    for (final value in [
      'fake-private-corrupt-record',
      '[]',
      '{}',
      '{"client_id":"wrong","access_token":"fake-private","refresh_token":"fake"}',
      '{"client_id":"test-issued-client-a","access_token":12,"refresh_token":"fake"}',
    ]) {
      FlutterSecureStorage.setMockInitialValues({key: value});
      await expectLater(
        const ChatGptCredentialStore().read(first.clientId),
        throwsA(isA<CredentialStorageException>()),
      );
    }
    expect(first.toString(), isNot(contains(first.accessToken)));
    expect(first.toString(), isNot(contains(first.refreshToken)));
    expect(
      const CredentialStorageException().toString(),
      isNot(contains('fake-private')),
    );
  });
}
