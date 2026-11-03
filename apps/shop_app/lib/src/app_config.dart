/// Build-time configuration.
///
/// The base URL is the one thing that changes between dev, staging and
/// production, so it lives here and nowhere else. When the client's own
/// Cloudflare account takes over, only this line and the DNS record change.
abstract final class AppConfig {
  /// Development Worker. Production will be `https://api.starparis.ae` once the
  /// client owns the account (PLAN.md §19 item 9).
  static const String apiBaseUrl =
      'https://starparis-api.theblacklightstudio.workers.dev';

  static const String appVersion = '0.1.0';

  /// Sync intervals from the design document §5.5.
  static const Duration windowsPollInterval = Duration(seconds: 15);
  static const Duration androidPollInterval = Duration(seconds: 30);
}
