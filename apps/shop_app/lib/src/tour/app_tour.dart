import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../screens/home_screen.dart' show HomeTabs;
import 'spotlight_tour.dart';

/// Named targets the global tour can spotlight.
///
/// They all live in the shell — the navigation rail, the search box, the sync
/// chip, the user menu — so they are laid out for the whole session and a step
/// can point at one regardless of which screen is showing underneath.
class TourAnchors {
  final GlobalKey rail = GlobalKey();
  final GlobalKey search = GlobalKey();
  final GlobalKey sync = GlobalKey();
  final GlobalKey menu = GlobalKey();

  GlobalKey? forName(String? name) => switch (name) {
        'rail' => rail,
        'search' => search,
        'sync' => sync,
        'menu' => menu,
        _ => null,
      };
}

final Provider<TourAnchors> tourAnchorsProvider =
    Provider<TourAnchors>((ref) => TourAnchors());

/// The get-started tour, in the order a new clerk first walks the app.
const List<TourStep> appTourSteps = <TourStep>[
  TourStep(
    icon: Icons.local_print_shop_outlined,
    title: 'Welcome to Star Paris',
    body:
        'A job moves from a quote, to the floor, to an invoice — all in one '
        'place, and it keeps working with no internet. Let\'s look around in '
        'under a minute.',
  ),
  TourStep(
    anchor: 'rail',
    icon: Icons.dashboard_outlined,
    title: 'This is your navigation',
    body:
        'Today, Orders, Customers and Production live in this rail. Tap any '
        'one to jump to that screen — the highlight shows you where to look.',
  ),
  TourStep(
    anchor: 'rail',
    icon: Icons.receipt_long_outlined,
    title: 'Orders — every job starts here',
    body:
        'Open Orders, then tap "New order" (or press Ctrl+N) to build a quote '
        'and turn it into a job. Every screen also teaches itself — watch for '
        'a short guide the first time you open one.',
  ),
  TourStep(
    anchor: 'rail',
    icon: Icons.people_outline,
    title: 'Customers — find anyone in seconds',
    body:
        'Search by name or phone, then tap a customer for their orders, '
        'balance and a statement.',
  ),
  TourStep(
    anchor: 'rail',
    icon: Icons.view_kanban_outlined,
    title: 'The production board',
    body:
        'Every job is a card in a column. Claim, start and finish each stage '
        'so everyone sees where a job is.',
  ),
  TourStep(
    anchor: 'search',
    icon: Icons.search,
    title: 'Answer "where\'s my order?"',
    body:
        'Type a job number, invoice, phone or name here — the answer comes '
        'back grouped. Works offline. Press Ctrl+K from anywhere.',
  ),
  TourStep(
    anchor: 'sync',
    icon: Icons.cloud_outlined,
    title: 'Online, offline or syncing',
    body:
        'This chip tells you the connection state. The app keeps working '
        'offline and syncs when the network returns.',
  ),
  TourStep(
    anchor: 'menu',
    icon: Icons.account_circle_outlined,
    title: 'Your account lives here',
    body:
        'Cash drawer, theme, language and sign out. Replay this tour or any '
        'screen\'s guide from here any time.',
  ),
  TourStep(
    icon: Icons.check_circle_outline,
    title: 'You\'re ready',
    body: 'F5 syncs now, Ctrl+K finds a job, Ctrl+N starts an order. Go make '
        'something.',
  ),
];

/// The shell tab to open before each step (null = keep the current tab), so
/// the screen behind the spotlight matches what the step explains. Parallel to
/// [appTourSteps].
const List<int?> appTourStepTabs = <int?>[
  null, // welcome (centred card)
  HomeTabs.home,
  HomeTabs.orders,
  HomeTabs.customers,
  HomeTabs.production,
  null, // search box lives in the shell, on any tab
  null, // sync chip lives in the shell, on any tab
  null, // user menu lives in the shell, on any tab
  null, // closing (centred card)
];

@immutable
class AppTourState {
  const AppTourState({required this.active, required this.step});

  final bool active;
  final int step;

  bool get isLast => step >= appTourSteps.length - 1;
}

/// Drives the tour, remembers it has been seen, and switches the shell tab to
/// match the step (so the screen behind the spotlight is the one being
/// explained).
class AppTourController extends Notifier<AppTourState> {
  static const String _metaKey = 'tour_seen';

  @override
  AppTourState build() {
    unawaited(_restore());
    return const AppTourState(active: false, step: 0);
  }

  Future<void> _restore() async {
    try {
      final seen = await ref.read(bootstrapProvider).db.meta(_metaKey);
      if (seen != '1') start();
    } catch (_) {
      // A fresh device with no database yet simply skips the tour rather than
      // blocking the shell on a read that cannot have been written.
    }
  }

  void _go(int step) {
    state = AppTourState(active: true, step: step);
    final tab = appTourStepTabs[step];
    if (tab != null) ref.read(shellTabProvider.notifier).select(tab);
  }

  void start() => _go(0);

  void next() {
    if (state.isLast) {
      finish();
      return;
    }
    _go(state.step + 1);
  }

  void back() {
    if (state.step == 0) return;
    _go(state.step - 1);
  }

  Future<void> finish() async {
    state = AppTourState(active: false, step: state.step);
    try {
      await ref.read(bootstrapProvider).db.setMeta(_metaKey, '1');
    } catch (_) {}
  }
}

final NotifierProvider<AppTourController, AppTourState> appTourProvider =
    NotifierProvider<AppTourController, AppTourState>(AppTourController.new);

/// Hosts the get-started tour's coach-mark overlay. The overlay itself lives
/// in [SpotlightOverlay]; this only wires the global tour's controller to it.
class AppTourOverlay extends ConsumerWidget {
  const AppTourOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tour = ref.watch(appTourProvider);
    if (!tour.active) return const SizedBox.shrink();

    final anchors = ref.watch(tourAnchorsProvider);
    return SpotlightOverlay(
      steps: appTourSteps,
      index: tour.step,
      anchorFor: anchors.forName,
      onNext: () => ref.read(appTourProvider.notifier).next(),
      onBack: () => ref.read(appTourProvider.notifier).back(),
      onDone: () => ref.read(appTourProvider.notifier).finish(),
    );
  }
}
