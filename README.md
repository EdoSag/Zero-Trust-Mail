# Zero-Trust Mail

Private email for the Zero-Trust suite. One app for the mail accounts you
already have and for encrypted `@ztmail.me` mailboxes. On the phone it is
called **ZT Mail**; in stores and on release pages, **Zero-Trust Mail**.
Same account, settings and look as the other Zero-Trust apps, built on
[Zero-Trust-Core](https://github.com/EdoSag/Zero-Trust-Core). Part of the
[Zero-Trust suite](https://zerotrust.bz).

> **Status: early.** Mail accounts can be added; reading and sending mail
> are not built yet, and `@ztmail.me` mailboxes are not open.

## What it does

What works today:

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

## Privacy

Like every Zero-Trust app, it is zero-knowledge: your data is encrypted on
your device, with keys made from your password, before anything is sent.
The server stores only ciphertext and your password itself is never
sent, so neither we nor anyone who breaks into the server can read your
data. The recovery key shown at sign-up is the only way back in if you
forget the password. How the keys work:
[Zero-Trust-Core](https://github.com/EdoSag/Zero-Trust-Core#key-hierarchy) and
[zerotrust.bz/security](https://zerotrust.bz/security/).

- An account's address and servers sync end-to-end encrypted. Passwords
  never sync: they stay in this phone's keystore.

## One account, one core

One Zero-Trust account opens every app in the suite. Sign-in, unlock
(fingerprint or face, auto-lock), the recovery key, settings, the look,
sync and languages come from
[Zero-Trust-Core](https://github.com/EdoSag/Zero-Trust-Core), so they work
the same in every app. Accounts made before the core still sign in and
see their data.

## Install

Android: signed APKs are published on this repository's
[Releases](https://github.com/EdoSag/Zero-Trust-Mail/releases) page. GitHub Releases are the
main way the apps are published.

Builds from GitHub check for a newer release themselves (Settings > About,
one anonymous request a day, can be turned off). Every Zero-Trust app is signed
with the same key, and Android only installs an update signed with it.

ZT Mail is not on the zerotrust.bz install page yet.

## Languages

English and Hebrew, with right-to-left layout. Choose under
Settings > Appearance > Language.

## How it is built

```
lib/
  app/        gate (sign-in, unlock), app config, email links
  accounts/   account model, synced account list, password store, presets
  protocol/   MailBackend interface and message models
  store/      MailCache
  ui/         account list, add/edit account, settings
  l10n/       English and Hebrew strings
```

## Build from source

Flutter 3.47.9, the version CI pins (3.50 deprecates `material.dart` and
fails analyze).

First create a file named `.env` in the project folder. It is not committed
(CI writes its own) and it is bundled into the APK, so it holds public client
values only, never a service-role key:

```
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_ANON_KEY=<publishable key>
```

Then:

```bash
flutter pub get
dart run zt_release_checks --app mail   # shared release checks
flutter analyze && flutter test test/
flutter run
```

Never add `cryptography_flutter`: it breaks the core's key derivation and
sign-in fails.

## Branches and releases

Work happens on `Dev`: pull requests target `Dev`, never `main`, and get a
test build. A release is one `Dev` → `main` pull request. Every push to
`main` runs the suite's release checks, builds a signed APK and a Google Play bundle
and publishes them as a GitHub Release named "Zero-Trust Mail"
(`.github/workflows/android-apk.yml`). The workflow needs the repository
secrets `ANDROID_KEYSTORE_BASE64` and `ANDROID_KEYSTORE_PASSWORD`, the
keystore shared by all Zero-Trust apps.

## Support and security

- Help centre: [zerotrust.bz/help](https://zerotrust.bz/help/). Questions and
  account deletion: support@zerotrust.bz.
- Security problems: please report them privately to cyber@zerotrust.bz. What
  the encryption does and doesn't protect against is on
  [zerotrust.bz/security](https://zerotrust.bz/security/).
- [Privacy policy](https://zerotrust.bz/privacy/) and
  [terms](https://zerotrust.bz/terms/).

## License

Copyright (C) 2026 Edo Sagron (https://zerotrust.bz)

Zero-Trust is open source under the [GNU Affero General Public License v3.0](LICENSE)
(AGPL-3.0-only), the same licence Signal uses.

- You may use, study, change and share the code, including in your own projects.
- If you share a changed version, or run it for other people over a network, you must
  publish your full source code under the same licence.
- This program comes with no warranty; see the licence for details.

Third-party libraries keep their own licences; the app lists them under
Settings > Open-source licences.

### Name and logo

The AGPL covers the code, not the brand. "Zero-Trust", "ZT", the app names and icons are
reserved. If you publish a fork, give it a different name and icon so nobody mistakes it
for an official Zero-Trust app.

### Servers

The official apps use the Zero-Trust servers. A fork must use its own backend (for
example its own Supabase project) and must not connect to the official servers.

### Contributing

Pull requests are welcome. By sending one you agree that your contribution is licensed
under the AGPL-3.0 and that the copyright holder may also license it under other terms,
including commercially. This keeps the project able to offer paid plans and other licences.
