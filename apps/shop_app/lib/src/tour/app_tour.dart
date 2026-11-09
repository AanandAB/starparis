import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';

import '../providers.dart';
import '../screens/home_screen.dart' show HomeTabs;

/// Named targets the tour can spotlight.
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

/// One step of the guided tour.
///
/// [anchor] names the shell element to spotlight (null for the welcome and
/// closing cards, which show centred instead). [tab] is the shell tab to open
/// first, so the screen behind the spotlight matches what the step explains.
class AppTourStep {
  const AppTourStep({
    required this.title,
    required this.body,
    this.icon = Icons.info_outline,
    this.anchor,
    this.tab,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? anchor;
  final int? tab;
}

/// The tour, in the order a new clerk first walks the app.
const List<AppTourStep> appTourSteps = <AppTourStep>[
  AppTourStep(
    icon: Icons.local_print_shop_outlined,
    title: 'Welcome to Star Paris',
    body:
        'A job moves from a quote, to the floor, to an invoice — all in one '
        'place, and it keeps working with no internet. Let\'s look around in '
        'under a minute.',
  ),
  AppTourStep(
    anchor: 'rail',
    tab: HomeTabs.home,
    icon: Icons.dashboard_outlined,
    title: 'This is your navigation',
    body:
        'Today, Orders, Customers and Production live in this rail. Tap any '
        'one to jump to that screen — the highlight shows you where to look.',
  ),
  AppTourStep(
    anchor: 'rail',
    tab: HomeTabs.orders,
    icon: Icons.receipt_long_outlined,
    title: 'Orders — every job starts here',
    body:
        'Open Orders, then tap "New order" (or press Ctrl+N) to build a quote '
        'and turn it into a job.',
  ),
  AppTourStep(
    anchor: 'rail',
    tab: HomeTabs.customers,
    icon: Icons.people_outline,
    title: 'Customers — find anyone in seconds',
    body:
        'Search by name or phone, then tap a customer for their orders, '
        'balance and a statement.',
  ),
  AppTourStep(
    anchor: 'rail',
    tab: HomeTabs.production,
    icon: Icons.view_kanban_outlined,
    title: 'The production board',
    body:
        'Every job is a card in a column. Claim, start and finish each stage '
        'so everyone sees where a job is.',
  ),
  AppTourStep(
    anchor: 'search',
    icon: Icons.search,
    title: 'Answer "where\'s my order?"',
    body:
        'Type a job number, invoice, phone or name here — the answer comes '
        'back grouped. Works offline. Press Ctrl+K from anywhere.',
  ),
  AppTourStep(
    anchor: 'sync',
    icon: Icons.cloud_outlined,
    title: 'Online, offline or syncing',
    body:
        'This chip tells you the connection state. The app keeps working '
        'offline and syncs when the network returns.',
  ),
  AppTourStep(
    anchor: 'menu',
    icon: Icons.account_circle_outlined,
    title: 'Your account lives here',
    body:
        'Cash drawer, theme, language and sign out. You can replay this tour '
        'any time from this menu.',
  ),
  AppTourStep(
    icon: Icons.check_circle_outline,
    title: 'You\'re ready',
    body: 'F5 syncs now, Ctrl+K finds a job, Ctrl+N starts an order. Go make '
        'something.',
  ),
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
    final tab = appTourSteps[step].tab;
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

/// The coach-mark overlay: dims the app, punches a spotlight hole over the
/// element the current step is about, draws a highlight border around it, and
/// anchors a small tooltip beside it. The app stays visible so the user can
/// actually see what is being pointed at.
class AppTourOverlay extends ConsumerStatefulWidget {
  const AppTourOverlay({super.key});

  @override
  ConsumerState<AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends ConsumerState<AppTourOverlay> {
  Rect? _targetRect;
  GlobalKey? _key;

  @override
  Widget build(BuildContext context) {
    final tour = ref.watch(appTourProvider);
    if (!tour.active) return const SizedBox.shrink();

    final step = appTourSteps[tour.step];
    final anchors = ref.watch(tourAnchorsProvider);
    final key = anchors.forName(step.anchor);

    if (key != _key) {
      _key = key;
      _targetRect = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure(key));

    final theme = Theme.of(context);
    final screen = MediaQuery.sizeOf(context);

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SpotlightPainter(_targetRect),
            ),
          ),
        ),
        if (_targetRect != null)
          AnimatedPositioned.fromRect(
            duration: StarMotion.standard,
            curve: StarMotion.easeOut,
            rect: _targetRect!.inflate(6),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(StarRadius.card),
                  border: Border.all(color: StarColors.petrol, width: 2),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: StarColors.petrol.withValues(alpha: 0.35),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_targetRect != null)
          _anchoredTooltip(tour, step, theme, screen)
        else
          _centeredCard(tour, step, theme),
      ],
    );
  }

  void _measure(GlobalKey? key) {
    if (key == null) {
      if (_targetRect != null) setState(() => _targetRect = null);
      return;
    }
    final ctx = key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect != _targetRect) setState(() => _targetRect = rect);
  }

  Widget _anchoredTooltip(
    AppTourState tour,
    AppTourStep step,
    ThemeData theme,
    Size screen,
  ) {
    const double maxWidth = 320;
    const double gap = 12;
    // The card is roughly this tall; use it to decide below vs above so the
    // tooltip never falls off the screen.
    const double estimateHeight = 170;
    final target = _targetRect!;
    final fitsBelow =
        target.bottom + gap + estimateHeight < screen.height - 8;
    final top = (fitsBelow
            ? target.bottom + gap
            : target.top - gap - estimateHeight)
        .clamp(8.0, screen.height - estimateHeight - 8.0);
    final left = (target.center.dx - maxWidth / 2)
        .clamp(8.0, screen.width - maxWidth - 8.0);

    return AnimatedPositioned(
      duration: StarMotion.standard,
      curve: StarMotion.easeOut,
      top: top,
      left: left,
      width: maxWidth,
      child: AnimatedSwitcher(
        duration: StarMotion.fast,
        switchInCurve: StarMotion.easeOut,
        switchOutCurve: StarMotion.easeInOut,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: _TooltipCard(
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
    );
  }

  Widget _centeredCard(
    AppTourState tour,
    AppTourStep step,
    ThemeData theme,
  ) {
    return Center(
      child: AnimatedSwitcher(
        duration: StarMotion.standard,
        switchInCurve: StarMotion.easeOut,
        switchOutCurve: StarMotion.easeInOut,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: _TooltipCard(
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
    );
  }
}

/// A compact glass card: icon + title + body, then Back / dots / Next. Kept
/// small on purpose — it is a hint beside the spotlight, not the whole screen.
class _TooltipCard extends StatelessWidget {
  const _TooltipCard({
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
    return GlassPanel(
      borderRadius: BorderRadius.circular(StarRadius.card),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          StarSpace.md,
          StarSpace.md,
          StarSpace.md,
          StarSpace.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(StarSpace.sm),
                  decoration: BoxDecoration(
                    color: StarColors.petrol.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(StarRadius.chip),
                  ),
                  child: Icon(step.icon, size: 20, color: StarColors.petrol),
                ),
                const SizedBox(width: StarSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        step.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: StarSpace.sm),
            Row(
              children: <Widget>[
                if (onBack != null)
                  IconButton(
                    tooltip: 'Back',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 18),
                  )
                else
                  TextButton(
                    onPressed: onSkip,
                    child: Text(isLast ? 'Done' : 'Skip'),
                  ),
                const Spacer(),
                _Dots(index: index, total: total),
                const Spacer(),
                IconButton.filled(
                  tooltip: 'Next',
                  onPressed: onNext,
                  icon: Icon(isLast ? Icons.check_rounded : Icons.arrow_forward),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.total});

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
            width: i == index ? 18 : 6,
            height: 6,
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

/// Dims the whole screen except a rounded hole over [hole]. When [hole] is
/// null (the welcome / closing cards) it dims evenly, with no cutout.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.hole);

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.6);
    final full = Offset.zero & size;

    if (hole == null) {
      canvas.drawRect(full, dim);
      return;
    }

    final cutout = RRect.fromRectAndRadius(
      hole!.inflate(8),
      const Radius.circular(12),
    );
    final fullPath = Path()..addRect(full);
    final holePath = Path()..addRRect(cutout);
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, holePath),
      dim,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole;
}
