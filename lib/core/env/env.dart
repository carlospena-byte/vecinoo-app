import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads Supabase connection settings from the `.env` file (see
/// `.env.example`), loaded once in `main()` before `runApp`.
class Env {
  Env._();

  static String get supabaseUrl {
    final url = dotenv.get('SUPABASE_URL');
    // The Android emulator's guest OS has its own loopback, so
    // 127.0.0.1/localhost there means the emulator itself, not the host
    // machine running `supabase start` — 10.0.2.2 is its alias for the
    // host's loopback. Every request would otherwise fail to connect and
    // surface as a generic error with no hint it's a networking issue.
    // The iOS Simulator shares the host's loopback directly, so it needs
    // no remapping.
    if (Platform.isAndroid) {
      return url
          .replaceFirst('127.0.0.1', '10.0.2.2')
          .replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  static String get supabasePublishableKey =>
      dotenv.get('SUPABASE_PUBLISHABLE_KEY');

  /// Base URL of the gates-admin web app, which serves the FastLane
  /// self-registration page at `#fastlane/<code>` — same link scheme the
  /// send-visit-notification Edge Function builds server-side.
  static String get publicAppUrl =>
      dotenv.maybeGet('PUBLIC_APP_URL') ?? 'https://admin.vecinoo.app/';
}
