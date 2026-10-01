import '../../../core/env/env.dart';

/// The FastLane self-registration link the resident shares with their
/// visitor — same `#fastlane/<code>` scheme the send-visit-notification
/// Edge Function builds server-side for the admin's SMS/WhatsApp flow.
String fastlaneLink(String accessCode) {
  final base = Env.publicAppUrl.endsWith('/')
      ? Env.publicAppUrl
      : '${Env.publicAppUrl}/';
  return '$base#fastlane/$accessCode';
}
