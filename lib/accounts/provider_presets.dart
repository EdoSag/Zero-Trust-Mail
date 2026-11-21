import 'mail_account.dart';

/// Server settings of the big providers, so most people only type their
/// address and password. Anything else is typed by hand for now (automatic
/// lookup comes with the IMAP client).
class ProviderPreset {
  const ProviderPreset({
    required this.name,
    required this.incoming,
    required this.outgoing,
    this.needsAppPassword = false,
  });

  final String name;
  final MailServer incoming;
  final MailServer outgoing;

  /// The provider refuses the normal account password from mail apps and
  /// wants one made for the app in its security settings.
  final bool needsAppPassword;

  static const _gmail = ProviderPreset(
    name: 'Gmail',
    incoming: MailServer(host: 'imap.gmail.com', port: 993),
    outgoing: MailServer(host: 'smtp.gmail.com', port: 465),
    needsAppPassword: true,
  );
  static const _icloud = ProviderPreset(
    name: 'iCloud',
    incoming: MailServer(host: 'imap.mail.me.com', port: 993),
    outgoing: MailServer(
      host: 'smtp.mail.me.com',
      port: 587,
      security: MailSecurity.startTls,
    ),
    needsAppPassword: true,
  );
  static const _yahoo = ProviderPreset(
    name: 'Yahoo',
    incoming: MailServer(host: 'imap.mail.yahoo.com', port: 993),
    outgoing: MailServer(host: 'smtp.mail.yahoo.com', port: 465),
    needsAppPassword: true,
  );
  static const _fastmail = ProviderPreset(
    name: 'Fastmail',
    incoming: MailServer(host: 'imap.fastmail.com', port: 993),
    outgoing: MailServer(host: 'smtp.fastmail.com', port: 465),
    needsAppPassword: true,
  );

  static const _byDomain = <String, ProviderPreset>{
    'gmail.com': _gmail,
    'googlemail.com': _gmail,
    'icloud.com': _icloud,
    'me.com': _icloud,
    'mac.com': _icloud,
    'yahoo.com': _yahoo,
    'fastmail.com': _fastmail,
    'fastmail.fm': _fastmail,
  };

  /// The preset for [email]'s provider, or null when it isn't one of them.
  static ProviderPreset? forEmail(String email) {
    final at = email.lastIndexOf('@');
    if (at < 0) return null;
    return _byDomain[email.substring(at + 1).trim().toLowerCase()];
  }
}
