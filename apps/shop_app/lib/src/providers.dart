import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_sync/starparis_sync.dart';

import 'auth/session.dart';
import 'bootstrap.dart';

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

/// Which shell tab is open. A provider rather than local state so a card on the
/// home screen can send the user to the customers tab with one tap.
class ShellTab extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final NotifierProvider<ShellTab, int> shellTabProvider =
    NotifierProvider<ShellTab, int>(ShellTab.new);
