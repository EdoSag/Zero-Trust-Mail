// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get remove => 'Remove';

  @override
  String get accounts => 'Mail accounts';

  @override
  String get addAccount => 'Add account';

  @override
  String get editAccount => 'Edit account';

  @override
  String get noAccountsTitle => 'Add your first mail account';

  @override
  String get noAccountsBody =>
      'Use the mail you already have: Gmail, Outlook, iCloud or any other provider. Your password stays on this phone.';

  @override
  String get comingSoon =>
      'Reading and sending mail arrives in the next update. Your accounts are saved and ready.';

  @override
  String get passwordNeeded => 'Password needed on this phone';

  @override
  String get protocolImap => 'IMAP';

  @override
  String get protocolJmap => 'JMAP';

  @override
  String get protocolZtMailbox => 'ZT Mail mailbox';

  @override
  String get yourName => 'Your name';

  @override
  String get yourNameHint => 'Shown to people you write to';

  @override
  String get email => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get passwordKeep => 'Leave empty to keep the saved password';

  @override
  String appPasswordHint(String provider) {
    return '$provider needs an app password, not your normal one. Create it in your $provider account\'s security settings.';
  }

  @override
  String get serverSettings => 'Server settings';

  @override
  String get incomingServer => 'Incoming server (IMAP)';

  @override
  String get outgoingServer => 'Outgoing server (SMTP)';

  @override
  String get port => 'Port';

  @override
  String get username => 'Sign-in name';

  @override
  String get usernameHint => 'Only if it differs from your email address';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get invalidHost => 'Enter a server name, like imap.example.com';

  @override
  String get invalidPort => 'Enter a port from 1 to 65535';

  @override
  String get passwordRequired => 'Enter the password';

  @override
  String get accountExists => 'This account is already added';

  @override
  String get accountSaved => 'Account saved';

  @override
  String get removeAccountTitle => 'Remove this account?';

  @override
  String removeAccountBody(String email) {
    return '$email is removed from ZT Mail on all your devices. Your mail stays with your provider.';
  }

  @override
  String get accountRemoved => 'Account removed';

  @override
  String get saveFailed => 'Could not save. Try again.';
}
