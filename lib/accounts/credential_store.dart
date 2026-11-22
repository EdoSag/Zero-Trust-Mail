import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Account passwords and tokens, kept on this phone only (Android
/// Keystore / iOS Keychain). They are not part of sync: a new phone asks
/// for each account's password again.
abstract interface class CredentialStore {
  Future<String?> read(String accountId);
  Future<void> write(String accountId, String secret);
  Future<void> delete(String accountId);
}

class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String _key(String accountId) => 'zt_mail_secret_$accountId';

  @override
  Future<String?> read(String accountId) => _storage.read(key: _key(accountId));

  @override
  Future<void> write(String accountId, String secret) =>
      _storage.write(key: _key(accountId), value: secret);

  @override
  Future<void> delete(String accountId) =>
      _storage.delete(key: _key(accountId));
}

class InMemoryCredentialStore implements CredentialStore {
  final Map<String, String> secrets = {};

  @override
  Future<String?> read(String accountId) async => secrets[accountId];

  @override
  Future<void> write(String accountId, String secret) async =>
      secrets[accountId] = secret;

  @override
  Future<void> delete(String accountId) async => secrets.remove(accountId);
}

final credentialStoreProvider = Provider<CredentialStore>(
  (ref) => SecureCredentialStore(),
);
