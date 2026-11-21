import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import 'credential_store.dart';
import 'mail_account.dart';

/// Mail accounts are items of the Mail app, sealed with its own key
/// (`app = 'mail'`, `kind` mail_account). No database change. An item this
/// version can't read is kept and skipped.
final accountsCollection = ZtCollection<MailAccount?>(
  kind: 'mail_account',
  fromJson: (id, json, _) => MailAccount.fromJson(id, json),
  toJson: (a) => a!.toJson(),
  idOf: (a) => a!.id,
);

List<MailAccount> _sorted(Iterable<MailAccount?> accounts) =>
    accounts.whereType<MailAccount>().toList()..sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.email.compareTo(b.email);
    });

final accountsProvider = StreamProvider<List<MailAccount>>((ref) async* {
  final store = await ref.watch(ztLocalStoreProvider.future);
  if (store is ZtLocalStore) {
    yield* accountsCollection.watch(store).map(_sorted);
  } else {
    yield _sorted(await accountsCollection.list(store));
  }
});

/// Whether this phone holds the password of the account with this id.
final accountHasSecretProvider = FutureProvider.family<bool, String>((ref, id) {
  // Asked again when the account list changes (a save may add the secret).
  ref.watch(accountsProvider);
  return ref.watch(accountsRepositoryProvider).hasSecret(id);
});

final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => AccountsRepository(ref),
);

/// Saves and deletes through the shared sync controller, so every change is
/// encrypted, stored locally and sent to the account's other devices. The
/// password goes to this phone's [CredentialStore] only.
class AccountsRepository {
  AccountsRepository(this._ref);
  final Ref _ref;

  static const _uuid = Uuid();
  static String newId() => _uuid.v4();

  SyncController get _sync => _ref.read(ztSyncControllerProvider.notifier);
  Future<LocalItemStore> get _store => _ref.read(ztLocalStoreProvider.future);
  CredentialStore get _secrets => _ref.read(credentialStoreProvider);

  Future<List<MailAccount>> all() async =>
      _sorted(await accountsCollection.list(await _store));

  /// Saves [account]; with [secret], also its password on this phone.
  Future<void> save(MailAccount account, {String? secret}) async {
    if (secret != null) await _secrets.write(account.id, secret);
    await accountsCollection.save(_sync, await _store, account);
  }

  /// Removes the account from every device and its password from this one.
  Future<void> delete(String id) async {
    await accountsCollection.delete(_sync, id);
    await _secrets.delete(id);
  }

  /// Whether this phone holds the account's password. False on a phone the
  /// account synced to but was never signed in on.
  Future<bool> hasSecret(String id) async =>
      (await _secrets.read(id))?.isNotEmpty ?? false;
}
