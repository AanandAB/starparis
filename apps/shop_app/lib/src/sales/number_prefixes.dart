import 'package:starparis_sync/starparis_sync.dart';

import 'settings_service.dart';

/// The number prefixes the shop saved, in the shape the numbering code wants.
///
/// `ShopSettings` is the app's view of `GET /v1/settings`; `NumberPrefixes` is
/// the sync engine's. This is the one place the two meet, so no screen has to
/// remember that Settings calls the job prefix `order_prefix` — and so the next
/// kind of number only has to be mapped here instead of at every call site.
extension ShopSettingsNumbers on ShopSettings {
  NumberPrefixes get numberPrefixes => NumberPrefixes(
    job: orderPrefix,
    quote: quotePrefix,
    invoice: invoicePrefix,
  );
}
