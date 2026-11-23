import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accounts/accounts_store.dart';
import '../accounts/mail_account.dart';
import '../accounts/provider_presets.dart';
import '../l10n/l10n.dart';
import 'common.dart';

/// Adds a mail account, or edits [account]. The address and servers sync
/// to the user's other devices; the password stays on this phone.
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key, this.account});

  final MailAccount? account;

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.account?.displayName);
  late final _email = TextEditingController(text: widget.account?.email);
  final _password = TextEditingController();
  late final _username = TextEditingController(text: widget.account?.username);
  late final _inHost = TextEditingController(
    text: widget.account?.incoming.host,
  );
  late final _inPort = TextEditingController(
    text: '${widget.account?.incoming.port ?? 993}',
  );
  late final _outHost = TextEditingController(
    text: widget.account?.outgoing?.host,
  );
  late final _outPort = TextEditingController(
    text: '${widget.account?.outgoing?.port ?? 465}',
  );

  ProviderPreset? _preset;

  /// The servers were filled from a preset and not touched since, so a
  /// different address may replace them.
  bool _serversFromPreset = false;
  bool _showPassword = false;
  bool _saving = false;

  bool get _editing => widget.account != null;

  @override
  void initState() {
    super.initState();
    _preset = ProviderPreset.forEmail(_email.text);
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _password,
      _username,
      _inHost,
      _inPort,
      _outHost,
      _outPort,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Fills the servers when the address is one of the known providers and
  /// the user hasn't typed servers of their own.
  void _emailChanged(String value) {
    final preset = ProviderPreset.forEmail(value);
    final untouched =
        _serversFromPreset || (_inHost.text.isEmpty && _outHost.text.isEmpty);
    setState(() {
      _preset = preset;
      if (preset != null && untouched) {
        _inHost.text = preset.incoming.host;
        _inPort.text = '${preset.incoming.port}';
        _outHost.text = preset.outgoing.host;
        _outPort.text = '${preset.outgoing.port}';
        _serversFromPreset = true;
      } else if (preset == null && _serversFromPreset) {
        // The address is no longer that provider's, so its servers would be
        // wrong. Servers the user typed are never cleared.
        _inHost.clear();
        _outHost.clear();
        _inPort.text = '993';
        _outPort.text = '465';
        _serversFromPreset = false;
      }
    });
  }

  /// 465 is TLS from the start; every other submission port upgrades.
  static MailSecurity _smtpSecurity(int port) =>
      port == 465 ? MailSecurity.tls : MailSecurity.startTls;

  /// 993 is TLS from the start; 143 upgrades.
  static MailSecurity _imapSecurity(int port) =>
      port == 143 ? MailSecurity.startTls : MailSecurity.tls;

  Future<void> _save() async {
    final l = context.l10n;
    if (_saving || !_form.currentState!.validate()) return;
    final email = _email.text.trim();
    final repo = ref.read(accountsRepositoryProvider);
    setState(() => _saving = true);
    try {
      final existing = await repo.all();
      final duplicate = existing.any(
        (a) =>
            a.id != widget.account?.id &&
            a.email.toLowerCase() == email.toLowerCase(),
      );
      if (duplicate) {
        if (mounted) showSnack(context, l.accountExists);
        return;
      }
      final inPort = int.parse(_inPort.text.trim());
      final outPort = int.parse(_outPort.text.trim());
      final account = MailAccount(
        id: widget.account?.id ?? AccountsRepository.newId(),
        email: email,
        displayName: _name.text.trim(),
        protocol: MailProtocol.imap,
        incoming: MailServer(
          host: _inHost.text.trim().toLowerCase(),
          port: inPort,
          security: _imapSecurity(inPort),
        ),
        outgoing: MailServer(
          host: _outHost.text.trim().toLowerCase(),
          port: outPort,
          security: _smtpSecurity(outPort),
        ),
        username: _username.text.trim() == email ? '' : _username.text.trim(),
        order: widget.account?.order ?? existing.length,
      );
      await repo.save(
        account,
        secret: _password.text.isEmpty ? null : _password.text,
      );
      if (!mounted) return;
      showSnack(context, l.accountSaved);
      Navigator.of(context).pop();
    } on Object {
      if (mounted) showSnack(context, l.saveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove() async {
    final l = context.l10n;
    final account = widget.account!;
    final ok = await confirm(
      context,
      title: l.removeAccountTitle,
      body: l.removeAccountBody(account.email),
      action: l.remove,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(accountsRepositoryProvider).delete(account.id);
      if (!mounted) return;
      showSnack(context, l.accountRemoved);
      Navigator.of(context).pop();
    } on Object {
      if (mounted) showSnack(context, l.saveFailed);
    }
  }

  String? _hostError(String? v) =>
      looksLikeHost(v ?? '') ? null : context.l10n.invalidHost;

  String? _portError(String? v) {
    final port = int.tryParse((v ?? '').trim());
    return port != null && port >= 1 && port <= 65535
        ? null
        : context.l10n.invalidPort;
  }

  Widget _server(
    String label,
    TextEditingController host,
    TextEditingController port,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: host,
            decoration: InputDecoration(labelText: label),
            keyboardType: TextInputType.url,
            autocorrect: false,
            textDirection: TextDirection.ltr,
            validator: _hostError,
            onChanged: (_) => _serversFromPreset = false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: port,
            decoration: InputDecoration(labelText: context.l10n.port),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textDirection: TextDirection.ltr,
            validator: _portError,
            onChanged: (_) => _serversFromPreset = false,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final preset = _preset;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? l.editAccount : l.addAccount),
        actions: [
          if (_editing)
            IconButton(
              tooltip: l.remove,
              icon: const Icon(Icons.delete_outline),
              onPressed: _remove,
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: l.email),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.email],
              validator: (v) => looksLikeEmail(v ?? '') ? null : l.invalidEmail,
              onChanged: _emailChanged,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              decoration: InputDecoration(
                labelText: l.password,
                helperText: _editing ? l.passwordKeep : null,
                helperMaxLines: 2,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
              obscureText: !_showPassword,
              autocorrect: false,
              enableSuggestions: false,
              textDirection: TextDirection.ltr,
              validator: (v) =>
                  _editing || (v ?? '').isNotEmpty ? null : l.passwordRequired,
            ),
            if (preset != null && preset.needsAppPassword)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.appPasswordHint(preset.name),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: l.yourName,
                helperText: l.yourNameHint,
              ),
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
            ),
            const SizedBox(height: 24),
            Text(l.serverSettings, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _server(l.incomingServer, _inHost, _inPort),
            const SizedBox(height: 12),
            _server(l.outgoingServer, _outHost, _outPort),
            const SizedBox(height: 12),
            TextFormField(
              controller: _username,
              decoration: InputDecoration(
                labelText: l.username,
                helperText: l.usernameHint,
                helperMaxLines: 2,
              ),
              autocorrect: false,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}
