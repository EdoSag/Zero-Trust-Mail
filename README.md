# Zero-Trust Mail

Private email for the Zero-Trust suite (on the phone: **ZT Mail**). One app
for the mail accounts you already have and for encrypted `@ztmail.me`
mailboxes. Same account, settings and look as the other Zero-Trust apps,
built on [Zero-Trust-Core](https://github.com/EdoSag/Zero-Trust-Core).

## Status

Early. What works today:

- The shared Zero-Trust account: sign in, unlock, recovery key, settings,
  English and Hebrew.
- **Mail accounts:** add, edit and remove accounts. Gmail, iCloud, Yahoo and
  Fastmail only need the address and an app password; other providers take
  their IMAP and SMTP servers.
- An account's address and servers sync end-to-end encrypted to your other
  devices (item kind `mail_account` of app `mail`). **Passwords never sync:**
  they stay in this phone's keystore, and another phone asks for them again.

Not yet: reading and sending mail. The pieces it will plug into are here:

- `lib/protocol/mail_backend.dart`: the one interface IMAP + SMTP and JMAP
  both implement, so screens and the cache never care which one an account
  uses.
- `lib/store/mail_cache.dart`: the phone's copy of folders, message lists and
  opened bodies. In memory for now; the encrypted on-disk cache implements
  the same interface.

## Layout

```
lib/
  app/        gate (sign-in, unlock), app config, email links
  accounts/   account model, synced account list, password store, presets
  protocol/   MailBackend interface and message models
  store/      MailCache
  ui/         account list, add/edit account, settings
  l10n/       English and Hebrew strings
```

## Building

```
flutter pub get
flutter analyze
flutter test test/
dart run zt_release_checks --app mail
```

Flutter is pinned to 3.47.9 in CI (see `.github/workflows/android-apk.yml`).
`.env` holds the public Supabase URL and key; CI writes it.

Work happens on the `Dev` branch; `main` holds releases.

License: AGPL-3.0, see [LICENSE](LICENSE).
