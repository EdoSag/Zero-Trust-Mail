import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';
import 'package:zerotrust_mail/accounts/accounts_store.dart';
import 'package:zerotrust_mail/accounts/credential_store.dart';
import 'package:zerotrust_mail/accounts/mail_account.dart';
import 'package:zerotrust_mail/app/mail_config.dart';
import 'package:zerotrust_mail/l10n/l10n.dart';

/// Keeps accounts in memory, in place of the encrypted store.
class MemoryAccounts extends AccountsRepository {
  MemoryAccounts(super.ref, this.secrets, List<MailAccount> accounts) {
    for (final a in accounts) {
      _accounts[a.id] = a;
    }
  }

  final InMemoryCredentialStore secrets;
  final _accounts = <String, MailAccount>{};
  final _changes = StreamController<void>.broadcast();

  List<MailAccount> get accounts =>
      _accounts.values.toList()..sort((a, b) => a.order.compareTo(b.order));

  Stream<List<MailAccount>> watch() async* {
    yield accounts;
    yield* _changes.stream.map((_) => accounts);
  }

  @override
  Future<List<MailAccount>> all() async => accounts;

  @override
  Future<void> save(MailAccount account, {String? secret}) async {
    if (secret != null) await secrets.write(account.id, secret);
    _accounts[account.id] = account;
    _changes.add(null);
  }

  @override
  Future<void> delete(String id) async {
    _accounts.remove(id);
    await secrets.delete(id);
    _changes.add(null);
  }

  @override
  Future<bool> hasSecret(String id) async =>
      (await secrets.read(id))?.isNotEmpty ?? false;
}

late MemoryAccounts repo;

/// [secrets] maps account ids to the passwords this "phone" holds.
Widget app(
  Widget home, {
  List<MailAccount> accounts = const [],
  Map<String, String> secrets = const {},
  Locale locale = ZtLanguages.english,
  Key? key,
}) {
  final store = InMemoryCredentialStore()..secrets.addAll(secrets);
  return ProviderScope(
    key: key,
    overrides: [
      ztAppConfigProvider.overrideWithValue(mailAppConfig),
      ztPreferencesStoreProvider.overrideWithValue(InMemoryPreferencesStore()),
      credentialStoreProvider.overrideWithValue(store),
      accountsRepositoryProvider.overrideWith(
        (ref) => repo = MemoryAccounts(ref, store, accounts),
      ),
      accountsProvider.overrideWith(
        (ref) =>
            (ref.watch(accountsRepositoryProvider) as MemoryAccounts).watch(),
      ),
    ],
    child: MaterialApp(
      // The suite's real theme: its full-width buttons break rows that a
      // plain theme lets through.
      theme: ZtTheme.light(accent: mailAppConfig.accent),
      locale: locale,
      supportedLocales: ZtLanguages.supported,
      localizationsDelegates: const [
        AppL10n.delegate,
        ...ZtLanguages.delegates,
      ],
      home: home,
    ),
  );
}

const work = MailAccount(
  id: 'a1',
  email: 'dana@example.com',
  displayName: 'Dana Levi',
  protocol: MailProtocol.imap,
  incoming: MailServer(host: 'imap.example.com', port: 993),
  outgoing: MailServer(
    host: 'smtp.example.com',
    port: 587,
    security: MailSecurity.startTls,
  ),
);
