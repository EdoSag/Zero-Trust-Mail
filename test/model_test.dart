import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_mail/accounts/mail_account.dart';
import 'package:zerotrust_mail/accounts/provider_presets.dart';
import 'package:zerotrust_mail/protocol/mail_backend.dart';
import 'package:zerotrust_mail/store/mail_cache.dart';

import 'support/app.dart';

MessageSummary message(String id, int day, {bool seen = false}) =>
    MessageSummary(
      id: id,
      folderId: 'INBOX',
      from: const MailAddress('noa@example.org', 'Noa'),
      subject: 'Message $id',
      date: DateTime.utc(2026, 11, day),
      seen: seen,
    );

void main() {
  group('MailAccount', () {
    test('survives a round trip through its synced form', () {
      final back = MailAccount.fromJson(work.id, work.toJson())!;
      expect(back.email, 'dana@example.com');
      expect(back.displayName, 'Dana Levi');
      expect(back.protocol, MailProtocol.imap);
      expect(back.incoming, work.incoming);
      expect(back.outgoing, work.outgoing);
      expect(back.outgoing!.security, MailSecurity.startTls);
      expect(back.signInName, 'dana@example.com');
    });

    test('the synced form never holds a password', () {
      final json = work.toJson();
      expect(
        json.keys,
        unorderedEquals([
          'email',
          'displayName',
          'protocol',
          'incoming',
          'outgoing',
          'username',
          'order',
        ]),
      );
    });

    test('an item it cannot read is skipped, not a crash', () {
      expect(MailAccount.fromJson('x', {'email': 'a@b.co'}), isNull);
      expect(
        MailAccount.fromJson('x', {
          ...work.toJson(),
          'protocol': 'carrier-pigeon',
        }),
        isNull,
      );
      expect(
        MailAccount.fromJson('x', {...work.toJson(), 'incoming': 'nope'}),
        isNull,
      );
    });

    test('a JMAP account has no outgoing server', () {
      const jmap = MailAccount(
        id: 'j',
        email: 'me@ztmail.me',
        protocol: MailProtocol.ztMailbox,
        incoming: MailServer(host: 'mx1.ztmail.me', port: 443),
      );
      final back = MailAccount.fromJson('j', jmap.toJson())!;
      expect(back.outgoing, isNull);
      expect(back.protocol, MailProtocol.ztMailbox);
      expect(back.label, 'me@ztmail.me');
    });

    test('address and server checks', () {
      expect(looksLikeEmail('dana@example.com'), isTrue);
      expect(looksLikeEmail(' dana@example.co.il '), isTrue);
      expect(looksLikeEmail('dana@example'), isFalse);
      expect(looksLikeEmail('dana example.com'), isFalse);
      expect(looksLikeEmail('a@b@c.com'), isFalse);
      expect(looksLikeHost('imap.example.com'), isTrue);
      expect(looksLikeHost('mx1.ztmail.me'), isTrue);
      expect(looksLikeHost('localhost'), isFalse);
      expect(looksLikeHost('imap example.com'), isFalse);
      expect(looksLikeHost('https://imap.example.com'), isFalse);
      expect(looksLikeHost('-bad.example.com'), isFalse);
    });
  });

  group('ProviderPreset', () {
    test('knows the big providers, whatever the case', () {
      final gmail = ProviderPreset.forEmail('Someone@GMAIL.com')!;
      expect(
        gmail.incoming,
        const MailServer(host: 'imap.gmail.com', port: 993),
      );
      expect(
        gmail.outgoing,
        const MailServer(host: 'smtp.gmail.com', port: 465),
      );
      expect(gmail.needsAppPassword, isTrue);
      final icloud = ProviderPreset.forEmail('x@me.com')!;
      expect(icloud.outgoing.port, 587);
      expect(icloud.outgoing.security, MailSecurity.startTls);
    });

    test('is null for anything else', () {
      expect(ProviderPreset.forEmail('dana@example.com'), isNull);
      expect(ProviderPreset.forEmail('not an address'), isNull);
      // Not fooled by a look-alike in the local part.
      expect(ProviderPreset.forEmail('gmail.com@example.com'), isNull);
    });
  });

  group('MemoryMailCache', () {
    test('lists newest first and pages', () async {
      final cache = MemoryMailCache();
      await cache.applyChanges(
        'a',
        'INBOX',
        FolderChanges(
          state: 's1',
          upserted: [message('1', 1), message('3', 3), message('2', 2)],
        ),
      );
      final all = await cache.messages('a', 'INBOX');
      expect(all.map((m) => m.id), ['3', '2', '1']);
      final page = await cache.messages('a', 'INBOX', limit: 1, offset: 1);
      expect(page.single.id, '2');
      expect(await cache.folderState('a', 'INBOX'), 's1');
    });

    test('applies updates and removals, and forgets removed bodies', () async {
      final cache = MemoryMailCache();
      await cache.applyChanges(
        'a',
        'INBOX',
        FolderChanges(
          state: 's1',
          upserted: [message('1', 1), message('2', 2)],
        ),
      );
      await cache.putBody('a', 'INBOX', '1', const MessageBody(text: 'hello'));
      await cache.applyChanges(
        'a',
        'INBOX',
        FolderChanges(
          state: 's2',
          upserted: [message('2', 2, seen: true)],
          removedIds: const ['1'],
        ),
      );
      final all = await cache.messages('a', 'INBOX');
      expect(all.single.id, '2');
      expect(all.single.seen, isTrue);
      expect(await cache.body('a', 'INBOX', '1'), isNull);
      expect(await cache.folderState('a', 'INBOX'), 's2');
    });

    test('a resync replaces the folder', () async {
      final cache = MemoryMailCache();
      await cache.applyChanges(
        'a',
        'INBOX',
        FolderChanges(
          state: 's1',
          upserted: [message('1', 1), message('2', 2)],
        ),
      );
      await cache.applyChanges(
        'a',
        'INBOX',
        FolderChanges(state: 's9', upserted: [message('7', 7)], resync: true),
      );
      expect((await cache.messages('a', 'INBOX')).single.id, '7');
    });

    test(
      'accounts and folders are kept apart; clearing one leaves the other',
      () async {
        final cache = MemoryMailCache();
        for (final account in ['a', 'ab']) {
          await cache.putFolders(account, const [
            MailFolder(id: 'INBOX', name: 'Inbox', role: FolderRole.inbox),
          ]);
          await cache.applyChanges(
            account,
            'INBOX',
            FolderChanges(state: account, upserted: [message('1', 1)]),
          );
          await cache.putBody(
            account,
            'INBOX',
            '1',
            MessageBody(text: 'for $account'),
          );
        }
        await cache.applyChanges(
          'a',
          'Sent',
          FolderChanges(state: 'x', upserted: [message('5', 5)]),
        );
        expect((await cache.messages('a', 'INBOX')).single.id, '1');

        await cache.clearAccount('a');
        expect(await cache.folders('a'), isEmpty);
        expect(await cache.messages('a', 'INBOX'), isEmpty);
        expect(await cache.messages('a', 'Sent'), isEmpty);
        expect(await cache.folderState('a', 'INBOX'), isNull);
        expect(await cache.body('a', 'INBOX', '1'), isNull);
        // 'ab' starts with 'a' but is another account.
        expect((await cache.messages('ab', 'INBOX')).single.id, '1');
        expect((await cache.body('ab', 'INBOX', '1'))!.text, 'for ab');
        expect((await cache.folders('ab')).single.role, FolderRole.inbox);
      },
    );
  });
}
