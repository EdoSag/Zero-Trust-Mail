import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

/// The shared Zero-Trust settings screen. Mail's own rows join it as the
/// features that need them arrive.
class MailSettingsPage extends ConsumerWidget {
  const MailSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ZtSettingsPage(
      showSyncStatus: true,
      onSignedOut: () => Navigator.of(context).popUntil((r) => r.isFirst),
      onOpenUrl: (url) => launchUrl(url, mode: LaunchMode.externalApplication),
      privacyPolicyUrl: Uri.parse('https://zerotrust.bz/privacy'),
      termsUrl: Uri.parse('https://zerotrust.bz/terms'),
      supportUrl: Uri.parse('https://zerotrust.bz/support'),
    );
  }
}
