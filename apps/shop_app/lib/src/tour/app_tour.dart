import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';

import '../providers.dart';

/// One step of the guided tour. Written for a brand-new counter clerk, so each
/// step names one screen and what it is for — no jargon, no feature checklist.
class AppTourStep {
  const AppTourStep({
    required this.icon,
    required this.title,
    required this.body,
    this.tip,
  });

  final IconData icon;
  final String title;
  final String body;

  /// An optional one-line "how" hint, usually a keyboard shortcut.
  final String? tip;
}

/// The tour, in the order a new clerk first walks the app.
const List<AppTourStep> appTourSteps = <AppTourStep>[
  AppTourStep(
    icon: Icons.local_print_shop_outlined,
    title: 'Welcome to Star Paris',
    body:
        'This is your shop\'s command centre. A job moves from a quote, to the '
        'production floor, to an invoice and a payment — all in one place, and '
        'it keeps working even with no internet.',
    tip:
        'Tap through in a minute — you can replay this any time from the menu.',
  ),
  AppTourStep(
    icon: Icons.dashboard_outlined,
    title: 'Today is your dashboard',
    body:
        'The screen you land on. Every number is a door: what\'s in production, '
        'what\'s overdue, what\'s due today, and the work waiting for you.',
    tip: 'Tap any figure to jump to the list behind it.',
  ),
  AppTourStep(
    icon: Icons.receipt_long_outlined,
    title: 'Orders — where every job starts',
    body:
        'Build a quote, convert it to an order, invoice it, and WhatsApp the '
        'customer — all from the order. Each one gets a unique job number.',
    tip: 'Press Ctrl+N to start a new order from anywhere.',
  ),
  AppTourStep(
    icon: Icons.people_outline,
    title: 'Customers — find anyone in seconds',
    body:
        'Search by name or phone number. Open a customer to see their orders, '
        'their balance, and hand them a statement.',
  ),
  AppTourStep(
    icon: Icons.view_kanban_outlined,
    title: 'The production board',
    body:
        'Every job is a card in a column — design, print, finish, QC, delivery. '
        'Claim, start and finish each stage as the work moves, so everyone sees '
        'exactly where a job is.',
    tip: 'Switch between Board, My work and Vendors at the top.',
  ),
  AppTourStep(
    icon: Icons.price_change_outlined,
    title: 'Prices — you set them, no developer',
    body:
        'Edit any rate and see the effect on a sample quote before you save. '
        'Every change is recorded, so you always know who changed what and why.',
    tip: 'Owner only — this is locked for other roles.',
  ),
  AppTourStep(
    icon: Icons.search,
    title: 'Track — answer "where\'s my order?"',
    body:
        'Type a job number, invoice number, phone or customer name and the '
        'answer comes back grouped — jobs, invoices, customers. Works offline.',
    tip: 'Press Ctrl+K from anywhere to open it.',
  ),
  AppTourStep(
    icon: Icons.point_of_sale_outlined,
    title: 'You\'re ready',
    body:
        'That\'s the whole loop: sell, make, bill, collect. When in doubt, '
        'Ctrl+K finds the job and the sync chip in the top bar tells you the '
        'connection state.',
    tip: 'F5 syncs now. Replay this tour any time from the user menu.',
  ),
];

/// The tour's live state: whether it is showing and which step is current.
@immutable
class AppTourState {
  const AppTourState({required this.active, required this.step});

  final bool active;
  final int step;

  bool get isLast => step >= appTourSteps.length - 1;
}

/// Drives the tour and remembers that it has been seen.
///
/// Persisted to the same local meta table the theme and price-book version
/// already use (key `tour_seen`), so the tour plays once on first login and
/// never again unless it is replayed — no new store, no new dependency.
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

  void start() => state = const AppTourState(active: true, step: 0);

  void next() {
    if (state.isLast) {
      finish();
      return;
    }
    state = AppTourState(active: true, step: state.step + 1);
  }

  void back() {
    if (state.step == 0) return;
    state = AppTourState(active: true, step: state.step - 1);
  }

  /// Marks the tour seen and dismisses it. Best effort: if the write fails the
  /// tour simply plays again next login rather than corrupting anything.
  Future<void> finish() async {
    state = AppTourState(active: false, step: state.step);
    try {
      await ref.read(bootstrapProvider).db.setMeta(_metaKey, '1');
    } catch (_) {}
  }
}

final NotifierProvider<AppTourController, AppTourState> appTourProvider =
    NotifierProvider<AppTourController, AppTourState>(AppTourController.new);

/// The full-screen guided tour: a dimmed scrim over the app and an animated
/// glass card that walks through [appTourSteps] one at a time.
class AppTourOverlay extends ConsumerWidget {
  const AppTourOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tour = ref.watch(appTourProvider);
    if (!tour.active) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final step = appTourSteps[tour.step];

    return Stack(
      children: <Widget>[
        // The scrim: dims the app and swallows every tap, so the user cannot
        // wander off mid-tour. Tapping it does nothing on purpose — the only
        // way out is Skip or Done, so the tour is never dismissed by accident.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: StarMotion.standard,
              curve: StarMotion.easeOut,
              color: Colors.black.withValues(alpha: 0.58),
            ),
          ),
        ),
        Center(
          child: AnimatedSwitcher(
            duration: StarMotion.standard,
            switchInCurve: StarMotion.easeOut,
            switchOutCurve: StarMotion.easeInOut,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: _TourCard(
              key: ValueKey<int>(tour.step),
              step: step,
              index: tour.step,
              total: appTourSteps.length,
              isLast: tour.isLast,
              onBack: tour.step == 0
                  ? null
                  : () => ref.read(appTourProvider.notifier).back(),
              onNext: () => ref.read(appTourProvider.notifier).next(),
              onSkip: () => ref.read(appTourProvider.notifier).finish(),
              theme: theme,
            ),
          ),
        ),
      ],
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    super.key,
    required this.step,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.theme,
  });

  final AppTourStep step;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(StarSpace.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: GlassPanel(
          borderRadius: BorderRadius.circular(StarRadius.card),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              StarSpace.xl,
              StarSpace.xl,
              StarSpace.xl,
              StarSpace.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // The icon scales in with a soft elastic settle, so each new step
                // feels like a fresh reveal rather than a text swap.
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.5, end: 1),
                  duration: StarMotion.standard,
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Container(
                    padding: const EdgeInsets.all(StarSpace.md),
                    decoration: BoxDecoration(
                      color: StarColors.petrol.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(StarRadius.chip),
                    ),
                    child: Icon(step.icon, size: 30, color: StarColors.petrol),
                  ),
                ),
                const SizedBox(height: StarSpace.lg),
                Text(step.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: StarSpace.sm),
                Text(
                  step.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                if (step.tip != null) ...<Widget>[
                  const SizedBox(height: StarSpace.md),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: StarSpace.sm),
                      Expanded(
                        child: Text(
                          step.tip!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: StarSpace.lg),
                Row(
                  children: <Widget>[
                    TextButton(
                      onPressed: onSkip,
                      child: Text(isLast ? 'Done' : 'Skip'),
                    ),
                    const Spacer(),
                    _ProgressDots(index: index, total: total),
                    const Spacer(),
                    IconButton.filled(
                      tooltip: 'Next',
                      onPressed: onNext,
                      icon: Icon(
                        isLast ? Icons.check_rounded : Icons.arrow_forward,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: StarSpace.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: StarMotion.fast,
            curve: StarMotion.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index
                  ? StarColors.petrol
                  : Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(StarRadius.chip),
            ),
          ),
      ],
    );
  }
}
