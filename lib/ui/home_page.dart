import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accounts/accounts_store.dart';
import '../accounts/mail_account.dart';
import '../l10n/l10n.dart';
import 'account_page.dart';
import 'settings_page.dart';

/// The mail accounts, with Settings in the app bar. The inbox takes this
/// screen over once the IMAP client lands; accounts then move to Settings.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _openAccount(BuildContext context, [MailAccount? account]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AccountPage(account: account)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final accounts = ref.watch(accountsProvider);
    final list = accounts.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZT Mail'),
        actions: [
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MailSettingsPage()),
            ),
          ),
        ],
      ),
      body: switch (list) {
        null => const Center(child: CircularProgressIndicator()),
        [] => _Empty(onAdd: () => _openAccount(context)),
        _ => ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l.accounts,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final a in list)
              _AccountTile(account: a, onTap: () => _openAccount(context, a)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l.comingSoon,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      },
      floatingActionButton: list == null || list.isEmpty
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(l.addAccount),
              onPressed: () => _openAccount(context),
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l.noAccountsTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l.noAccountsBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l.addAccount),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile({required this.account, required this.onTap});
  final MailAccount account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final hasSecret = ref.watch(accountHasSecretProvider(account.id)).value;
    final protocol = switch (account.protocol) {
      MailProtocol.imap => l.protocolImap,
      MailProtocol.jmap => l.protocolJmap,
      MailProtocol.ztMailbox => l.protocolZtMailbox,
    };
    final named = account.displayName.isNotEmpty;
    return ListTile(
      leading: const Icon(Icons.alternate_email),
      title: Text(account.label),
      subtitle: Text(
        hasSecret == false
            ? l.passwordNeeded
            : named
            ? '${account.email} · $protocol'
            : protocol,
      ),
      trailing: hasSecret == false
          ? Icon(Icons.key_off, color: Theme.of(context).colorScheme.error)
          : null,
      onTap: onTap,
    );
  }
}
