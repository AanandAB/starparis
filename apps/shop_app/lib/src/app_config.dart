/// Build-time configuration.
///
/// The base URL is the one thing that changes between dev, staging and
/// production, so it lives here and nowhere else. When the client's own
/// Cloudflare account takes over, only this line and the DNS record change.
library;

import 'package:starparis_documents/starparis_documents.dart';

abstract final class AppConfig {
  /// Development Worker. Production will be `https://api.starparis.ae` once the
  /// client owns the account (PLAN.md §19 item 9).
  static const String apiBaseUrl =
      'https://starparis-api.theblacklightstudio.workers.dev';

  static const String appVersion = '0.1.0';

  /// Sync intervals from the design document §5.5.
  static const Duration windowsPollInterval = Duration(seconds: 15);
  static const Duration androidPollInterval = Duration(seconds: 30);

  /// Company details printed on documents. Real values arrive with the client's
  /// settings screen; until then these make the output honest and reviewable.
  static const CompanyProfile company = CompanyProfile(
    name: 'Star Paris Graphic LLC',
    trn: '100000000000003',
    address: 'Industrial Area 12, Sharjah, United Arab Emirates',
    phone: '+971 6 000 0000',
    email: 'hello@starparis.example',
    branchName: 'Sharjah — Industrial Area',
  );

  /// What the QR on a job ticket encodes. A custom scheme rather than a web URL
  /// on purpose: pointing the code at a page that does not exist yet would be a
  /// promise the ticket cannot keep. The handler is registered with the public
  /// tracking page in Phase 5; until then a scanner shows the job number.
  static const String jobQrPrefix = 'starparis://job/';

  /// Series codes for numbers. They belong in the settings screen; until that
  /// exists the pilot runs as the first counter at Sharjah (`SHJ1` / `PC1`), and
  /// every number it issues carries them: `INV-SHJ1-PC1-00001`.
  static const String branchCode = 'SHJ1';
  static const String deviceCode = 'PC1';
}
