import 'package:flutter/material.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

/// Mail in the suite. Not in the core's `ZtSuite` list yet, so the other
/// apps don't link to it before it's released.
const ZtSuiteApp mailSuiteApp = ZtSuiteApp(
  appId: 'mail',
  name: 'Mail',
  tagline: 'Private email for all your accounts',
  icon: Icons.mail_outline,
  accent: Color(0xFF06B6D4), // cyan
  androidPackage: 'dev.sagron.zerotrustmail',
);

const ZtAppConfig mailAppConfig = ZtAppConfig(
  appId: 'mail',
  displayName: 'Zero-Trust Mail',
  accent: Color(0xFF06B6D4),
);
