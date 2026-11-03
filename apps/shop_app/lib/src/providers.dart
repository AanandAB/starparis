import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_documents/starparis_documents.dart';
import 'package:starparis_sync/starparis_sync.dart';

import 'auth/session.dart';
import 'bootstrap.dart';
import 'app_config.dart';
import 'l10n/strings.dart';
import 'sales/settings_service.dart';

/// Overridden in `main()` with the real object; a missing override is a
/// programming error, not a runtime condition.
final Provider<Bootstrap> bootstrapProvider = Provider<Bootstrap>(
  (ref) => throw UnimplementedError('bootstrapProvider must be overridden'),
);

class SessionNotifier extends Notifier<Session?> {
  @override
  Session? build() => ref.watch(bootstrapProvider).initialSession;

  void signedIn(Session session) => state = session;

  Future<void> signOut() async {
    await ref.read(bootstrapProvider).signOut();
    state = null;
  }
}

final NotifierProvider<SessionNotifier, Session?> sessionProvider =
    NotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);

/// The sync loop's own state. Rebuilt when the session changes so a new user
/// never inherits the previous device's engine.
final StreamProvider<SyncState> syncStateProvider = StreamProvider<SyncState>((
  ref,
) {
  ref.watch(sessionProvider);
  final engine = ref.watch(bootstrapProvider).engine;
  return engine?.states ??
      Stream<SyncState>.value(
        const SyncState(phase: SyncPhase.idle, pending: 0),
      );
});

final StreamProvider<int> pendingCountProvider = StreamProvider<int>(
  (ref) => ref.watch(bootstrapProvider).db.watchPendingCount(),
);

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final NotifierProvider<SearchQuery, String> searchQueryProvider =
    NotifierProvider<SearchQuery, String>(SearchQuery.new);

/// Customers matching the search box. Empty query = the whole list, which is
/// what the counter sees when it opens the screen.
final StreamProvider<List<Customer>> customerResultsProvider =
    StreamProvider<List<Customer>>((ref) {
      final query = ref.watch(searchQueryProvider);
      return ref.watch(bootstrapProvider).db.searchCustomers(query);
    });

final StreamProvider<List<Customer>> allCustomersProvider =
    StreamProvider<List<Customer>>(
      (ref) => ref.watch(bootstrapProvider).db.watchCustomers(),
    );

final StreamProvider<List<Product>> productsProvider =
    StreamProvider<List<Product>>(
      (ref) => ref.watch(bootstrapProvider).db.watchProducts(),
    );

final StreamProvider<List<Order>> ordersProvider = StreamProvider<List<Order>>(
  (ref) => ref.watch(bootstrapProvider).db.watchOrders(),
);

/// The shop's machines and finishing catalogue, mirrored from /v1/catalogue.
final StreamProvider<List<Machine>> machinesProvider =
    StreamProvider<List<Machine>>(
      (ref) => ref.watch(bootstrapProvider).db.watchMachines(),
    );

final StreamProvider<List<Operation>> operationsProvider =
    StreamProvider<List<Operation>>(
      (ref) => ref.watch(bootstrapProvider).db.watchOperations(),
    );

/// The price rungs for one product, straight from the local catalogue.
final priceBreaksProvider = StreamProvider.family<List<PriceBreak>, String>(
  (ref, productId) => ref.watch(bootstrapProvider).db.watchBreaksFor(productId),
);

final StreamProvider<List<PriceRuleRow>> allRulesProvider =
    StreamProvider<List<PriceRuleRow>>(
      (ref) => ref.watch(bootstrapProvider).db.watchAllRules(),
    );

final StreamProvider<int> priceBookVersionProvider = StreamProvider<int>((ref) {
  return ref
      .watch(bootstrapProvider)
      .db
      .watchMeta('price_book_version')
      .map((value) => int.tryParse(value ?? '0') ?? 0);
});

/// Owner-only in the default matrix; the Worker enforces it regardless, so this
/// only decides whether the tab is worth showing.
final Provider<bool> canEditPricesProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider);
  return session?.role == 'owner';
});

/// Reports are whole-shop figures served by the API, and the permission matrix
/// gives `report.view` to owner, manager and accountant only.
final Provider<bool> canViewReportsProvider = Provider<bool>((ref) {
  final role = ref.watch(sessionProvider)?.role;
  return role == 'owner' || role == 'manager' || role == 'accountant';
});

/// Staff management is the owner's alone: `user.manage` in the permission
/// matrix, enforced by the Worker on every write.
final Provider<bool> canManageStaffProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider)?.role == 'owner';
});

/// Vendor work belongs to the owner, a manager and whoever coordinates vendors:
/// `vendor.manage` in the matrix.
final Provider<bool> canManageVendorsProvider = Provider<bool>((ref) {
  final role = ref.watch(sessionProvider)?.role;
  return role == 'owner' || role == 'manager' || role == 'vendor_coordinator';
});

/// Which language the interface is drawn in. Null follows the device.
class LocaleChoice extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void set(Locale? locale) => state = locale;

  void toggle() => state = state?.languageCode == 'ar'
      ? const Locale('en')
      : const Locale('ar', 'AE');
}

final NotifierProvider<LocaleChoice, Locale?> localeProvider =
    NotifierProvider<LocaleChoice, Locale?>(LocaleChoice.new);

/// The words for the current locale. A widget reads `ref.watch(stringsProvider)`.
final Provider<AppStrings> stringsProvider = Provider<AppStrings>((ref) {
  return AppStrings.of(ref.watch(localeProvider));
});

/// The shop's own details, loaded once and refreshed after a save.
///
/// Documents read the company from here, with the build-time profile as the
/// fallback: a device that has never reached the server still prints something
/// honest, and a shop that changes its TRN changes it everywhere at once.
final FutureProvider<ShopSettings> shopSettingsProvider =
    FutureProvider<ShopSettings>((ref) async {
      final bootstrap = ref.watch(bootstrapProvider);
      final service = SettingsService(
        baseUrl: AppConfig.apiBaseUrl,
        tokenProvider: bootstrap.auth.accessToken,
      );
      try {
        return await service.load();
      } catch (_) {
        return ShopSettings(
          company: AppConfig.company,
          vatBps: 500,
          orderPrefix: 'JOB',
          invoicePrefix: 'INV',
          quotePrefix: 'QT',
        );
      } finally {
        service.dispose();
      }
    });

final Provider<CompanyProfile> companyProvider = Provider<CompanyProfile>((
  ref,
) {
  return ref.watch(shopSettingsProvider).value?.company ?? AppConfig.company;
});

/// Which shell tab is open. A provider rather than local state so a card on the
/// home screen can send the user to the customers tab with one tap.
class ShellTab extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final NotifierProvider<ShellTab, int> shellTabProvider =
    NotifierProvider<ShellTab, int>(ShellTab.new);
