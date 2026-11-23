package dev.sagron.zerotrustmail

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * FlutterFragmentActivity, not FlutterActivity: the biometric prompt
 * (local_auth) needs a FragmentActivity.
 */
class MainActivity : FlutterFragmentActivity()
