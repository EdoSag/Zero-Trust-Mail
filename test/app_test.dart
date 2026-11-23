import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_mail/accounts/mail_account.dart';
import 'package:zerotrust_mail/ui/home_page.dart';

import 'support/app.dart';

Finder field(String label) => find.widgetWithText(TextFormField, label);

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first run: add a Gmail account with only address and password', (
    tester,
  ) async {
    await tester.pumpWidget(app(const HomePage()));
    await tester.pumpAndSettle();
    expect(find.text('Add your first mail account'), findsOneWidget);
    // The button sits under the explanation, not over it.
    final body = tester.getRect(
      find.textContaining('Use the mail you already'),
    );
    final button = tester.getRect(find.text('Add account'));
    expect(button.top, greaterThan(body.bottom));

    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Email address'), 'dana@gmail.com');
    await tester.pumpAndSettle();
    expect(find.textContaining('Gmail needs an app password'), findsOneWidget);
    await tester.enterText(field('Password'), 'abcd efgh ijkl mnop');
    await scrollTo(tester, find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = repo.accounts.single;
    expect(saved.email, 'dana@gmail.com');
    expect(saved.protocol, MailProtocol.imap);
    expect(saved.incoming, const MailServer(host: 'imap.gmail.com', port: 993));
    expect(saved.outgoing, const MailServer(host: 'smtp.gmail.com', port: 465));
    expect(saved.username, '');
    // The password went to this phone's store, not into the synced account.
    expect(repo.secrets.secrets[saved.id], 'abcd efgh ijkl mnop');
    expect(saved.toJson().toString(), isNot(contains('abcd')));

    // Back on the list, with the account on it.
    expect(find.text('dana@gmail.com'), findsOneWidget);
    expect(find.text('Add your first mail account'), findsNothing);
  });

  testWidgets('another provider: servers are typed, and checked', (
    tester,
  ) async {
    await tester.pumpWidget(app(const HomePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Email address'), 'dana@example');
    await scrollTo(tester, find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.accounts, isEmpty);
    await scrollTo(tester, find.text('Enter a valid email address'));
    expect(find.text('Enter the password'), findsOneWidget);

    await tester.enterText(field('Email address'), 'dana@example.com');
    await tester.enterText(field('Password'), 'secret');
    await scrollTo(tester, field('Incoming server (IMAP)'));
    await tester.enterText(field('Incoming server (IMAP)'), 'IMAP.example.com');
    await scrollTo(tester, field('Outgoing server (SMTP)'));
    await tester.enterText(field('Outgoing server (SMTP)'), 'smtp.example.com');
    await tester.enterText(find.widgetWithText(TextFormField, '465'), '587');
    await scrollTo(tester, find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = repo.accounts.single;
    expect(saved.incoming.host, 'imap.example.com');
    expect(saved.incoming.security, MailSecurity.tls);
    expect(saved.outgoing!.port, 587);
    expect(saved.outgoing!.security, MailSecurity.startTls);
  });

  testWidgets('typed servers are not replaced by a provider preset', (
    tester,
  ) async {
    await tester.pumpWidget(app(const HomePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();
    await scrollTo(tester, field('Incoming server (IMAP)'));
    await tester.enterText(field('Incoming server (IMAP)'), 'mail.own.net');
    await scrollTo(tester, field('Email address'));
    await tester.enterText(field('Email address'), 'dana@gmail.com');
    await tester.pumpAndSettle();
    await scrollTo(tester, field('Incoming server (IMAP)'));
    expect(find.text('mail.own.net'), findsOneWidget);
    expect(find.text('imap.gmail.com'), findsNothing);
  });

  testWidgets('a provider\'s servers go when the address changes provider', (
    tester,
  ) async {
    await tester.pumpWidget(app(const HomePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Email address'), 'dana@gmail.com');
    await tester.enterText(field('Password'), 'secret');
    await tester.pumpAndSettle();
    await tester.enterText(field('Email address'), 'dana@example.com');
    await tester.pumpAndSettle();
    await scrollTo(tester, field('Incoming server (IMAP)'));
    expect(find.text('imap.gmail.com'), findsNothing);
    expect(find.text('smtp.gmail.com'), findsNothing);

    // Nothing is saved with another provider's servers.
    await scrollTo(tester, find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.accounts, isEmpty);
  });

  testWidgets('the same address cannot be added twice', (tester) async {
    await tester.pumpWidget(
      app(const HomePage(), accounts: [work], secrets: {'a1': 'pw'}),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Email address'), 'DANA@example.com');
    await tester.enterText(field('Password'), 'secret');
    await scrollTo(tester, field('Incoming server (IMAP)'));
    await tester.enterText(field('Incoming server (IMAP)'), 'imap.example.com');
    await scrollTo(tester, field('Outgoing server (SMTP)'));
    await tester.enterText(field('Outgoing server (SMTP)'), 'smtp.example.com');
    await scrollTo(tester, find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('This account is already added'), findsOneWidget);
    expect(repo.accounts, hasLength(1));
  });

  testWidgets('an account synced from another phone asks for its password', (
    tester,
  ) async {
    await tester.pumpWidget(app(const HomePage(), accounts: [work]));
    await tester.pumpAndSettle();
    expect(find.text('Dana Levi'), findsOneWidget);
    expect(find.text('Password needed on this phone'), findsOneWidget);

    await tester.tap(find.text('Dana Levi'));
    await tester.pumpAndSettle();
    expect(find.text('Edit account'), findsOneWidget);
    await tester.enterText(field('Password'), 'now here');
    await scrollTo(tester, find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.secrets.secrets['a1'], 'now here');
    expect(find.text('Password needed on this phone'), findsNothing);
    expect(find.text('dana@example.com · IMAP'), findsOneWidget);
  });

  testWidgets('editing without a new password keeps the saved one', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const HomePage(), accounts: [work], secrets: {'a1': 'kept'}),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dana Levi'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Your name'), 'Dana L.');
    await scrollTo(tester, find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.accounts.single.displayName, 'Dana L.');
    expect(repo.accounts.single.id, 'a1');
    expect(repo.secrets.secrets['a1'], 'kept');
  });

  testWidgets('removing an account asks first and drops its password', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const HomePage(), accounts: [work], secrets: {'a1': 'pw'}),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dana Levi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    expect(find.textContaining('dana@example.com is removed'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.accounts, hasLength(1));

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(repo.accounts, isEmpty);
    expect(repo.secrets.secrets, isEmpty);
    expect(find.text('Add your first mail account'), findsOneWidget);
  });
}
