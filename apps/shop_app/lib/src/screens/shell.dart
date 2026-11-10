import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../providers.dart';
import '../theme_provider.dart';
import '../tour/app_tour.dart';
import '../tour/section_tour.dart';
import '../sales/till_sheet.dart';
import 'audit_screen.dart';
import 'board_screen.dart';
import 'catalogue_screen.dart';
import 'customers_screen.dart';
import 'diagnostics_sheet.dart';
import 'home_screen.dart';
import 'log_sheet.dart';
import 'orders_screen.dart';
import 'price_book_screen.dart';
import 'production_setup_screen.dart';
import 'quick_sale_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'staff_screen.dart';
import 'track_sheet.dart';
import 'vendors_screen.dart';

/// One place to go, and which page it shows.
class _Dest {
  const _Dest(this.label, this.icon, this.selectedIcon, this.page, this.id);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int page;

  /// Stable section id for the screen at [page] ('orders', 'customers', …).
  final String id;
}

/// The frame every screen lives in: navigation, search, sync state, user menu.
///
/// Layout follows width, not operating system: a rail on a desktop or a tablet
/// in landscape, a bottom bar on a phone. Pages keep stable indices (see
/// [HomeTabs]) so any screen can send the user somewhere without knowing how the
/// navigation is drawn.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  void _select(int page) => ref.read(shellTabProvider.notifier).select(page);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // A counter signs in to sell, not to read the dashboard: land them on the
      // quick-sale tab. POS is always the first optional page, so its index is
      // the stable [HomeTabs.pos].
      if (ref.read(sessionProvider)?.role == 'counter') {
        ref.read(shellTabProvider.notifier).select(HomeTabs.pos);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final index = ref.watch(shellTabProvider);
    final t = ref.watch(stringsProvider);
    final anchors = ref.watch(tourAnchorsProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final useRail =
        Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux ||
        width >= StarBreakpoints.medium;
    final wide = useRail && width >= 1200;

    // One list, grouped for the eye, keeping the page indices the rest of the
    // app already uses: Today 0, Customers 1, Orders 2, Production 3.
    final work = <_Dest>[
      _Dest(
        t('nav.today'),
        Icons.dashboard_outlined,
        Icons.dashboard,
        HomeTabs.home,
        'today',
      ),
      _Dest(
        t('nav.orders'),
        Icons.receipt_long_outlined,
        Icons.receipt_long,
        HomeTabs.orders,
        'orders',
      ),
      _Dest(
        t('nav.production'),
        Icons.view_kanban_outlined,
        Icons.view_kanban,
        HomeTabs.production,
        'production',
      ),
    ];
    final people = <_Dest>[
      _Dest(
        t('nav.customers'),
        Icons.people_outline,
        Icons.people,
        HomeTabs.customers,
        'customers',
      ),
    ];

    // The pages after Production are optional, one per role, so their indices
    // are counted rather than hard-coded: a manager has no Prices screen, and a
    // fixed index would then point at the wrong page.
    var nextPage = 4;
    final business = <_Dest>[];
    final optionalPages = <Widget>[];

    if (ref.watch(canUsePosProvider)) {
      business.add(
        _Dest(
          t('nav.quickSale'),
          Icons.point_of_sale_outlined,
          Icons.point_of_sale,
          nextPage++,
          'pos',
        ),
      );
      optionalPages.add(SectionTourHost(
        id: 'pos',
        steps: QuickSaleScreen.tourSteps,
        anchorFor: QuickSaleScreen.tourAnchorFor,
        child: const QuickSaleScreen(),
      ));
    }
    if (ref.watch(canEditPricesProvider)) {
      business.add(
        _Dest(
          t('nav.catalogue'),
          Icons.inventory_2_outlined,
          Icons.inventory_2,
          nextPage++,
          'catalogue',
        ),
      );
      optionalPages.add(SectionTourHost(
        id: 'catalogue',
        steps: CatalogueScreen.tourSteps,
        anchorFor: CatalogueScreen.tourAnchorFor,
        child: const CatalogueScreen(),
      ));
    }
    if (ref.watch(canEditPricesProvider)) {
      business.add(
        _Dest(
          t('nav.productionSetup'),
          Icons.tune_outlined,
          Icons.tune,
          nextPage++,
          'production_setup',
        ),
      );
      optionalPages.add(SectionTourHost(
        id: 'production_setup',
        steps: ProductionSetupScreen.tourSteps,
        anchorFor: ProductionSetupScreen.tourAnchorFor,
        child: const ProductionSetupScreen(),
      ));
    }
    if (ref.watch(canEditPricesProvider)) {
      business.add(
        _Dest(
          t('nav.prices'),
          Icons.price_change_outlined,
          Icons.price_change,
          nextPage++,
          'prices',
        ),
      );
      optionalPages.add(SectionTourHost(
        id: 'prices',
        steps: PriceBookScreen.tourSteps,
        anchorFor: PriceBookScreen.tourAnchorFor,
        child: const PriceBookScreen(),
      ));
    }
    if (ref.watch(canViewReportsProvider)) {
      business.add(
        _Dest(
          t('nav.reports'),
          Icons.insights_outlined,
          Icons.insights,
          nextPage++,
          'reports',
        ),
      );
      optionalPages.add(SectionTourHost(
        id: 'reports',
        steps: ReportsScreen.tourSteps,
        anchorFor: ReportsScreen.tourAnchorFor,
        child: const ReportsScreen(),
      ));
    }
    if (ref.watch(canManageStaffProvider)) {
      business.add(
        _Dest(t('nav.staff'), Icons.badge_outlined, Icons.badge, nextPage++, 'staff'),
      );
      optionalPages.add(SectionTourHost(
        id: 'staff',
        steps: StaffScreen.tourSteps,
        anchorFor: StaffScreen.tourAnchorFor,
        child: const StaffScreen(),
      ));
    }
    if (ref.watch(canManageStaffProvider)) {
      // Settings sits last: it is the rarest thing an owner opens.
      business.add(
        _Dest(
          t('nav.settings'),
          Icons.settings_outlined,
          Icons.settings,
          nextPage++,
          'settings',
        ),
      );
      optionalPages.add(const SettingsScreen());
    }
    if (ref.watch(canManageVendorsProvider)) {
      business.add(
        _Dest(
          t('nav.vendors'),
          Icons.storefront_outlined,
          Icons.storefront,
          nextPage++,
          'vendors',
        ),
      );
      optionalPages.add(SectionTourHost(
        id: 'vendors',
        steps: VendorsScreen.tourSteps,
        anchorFor: VendorsScreen.tourAnchorFor,
        child: const VendorsScreen(),
      ));
    }

    final pages = <Widget>[
      SectionTourHost(
        id: 'today',
        steps: HomeScreen.tourSteps,
        anchorFor: HomeScreen.tourAnchorFor,
        child: const HomeScreen(),
      ),
      SectionTourHost(
        id: 'customers',
        steps: CustomersScreen.tourSteps,
        anchorFor: CustomersScreen.tourAnchorFor,
        child: const CustomersScreen(),
      ),
      SectionTourHost(
        id: 'orders',
        steps: OrdersScreen.tourSteps,
        anchorFor: OrdersScreen.tourAnchorFor,
        child: const OrdersScreen(),
      ),
      SectionTourHost(
        id: 'production',
        steps: ProductionScreen.tourSteps,
        anchorFor: ProductionScreen.tourAnchorFor,
        child: const ProductionScreen(),
      ),
      ...optionalPages,
    ];

    final all = <_Dest>[...work, ...people, ...business];
    final current = all.firstWhere(
      (destination) => destination.page == index,
      orElse: () => all.first,
    );

    // Keep the section-tour hosts pointed at the visible tab. Set on a
    // post-frame callback rather than ref.listen: a listen only fires on
    // change and is attached after the session loads, so it can miss the
    // initial tab and the counter's sign-in landing tab. Setting every frame
    // is a no-op when the value is unchanged.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(activeSectionProvider.notifier).state = current.id;
      }
    });

    final body = IndexedStack(index: index, children: pages);

    // Global keys: a counter works at speed, and three of the most common
    // actions should not need the mouse.
    return Stack(
      children: <Widget>[
        CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
                showTrackSheet(context),
            const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
                openOrderBuilder(context),
            const SingleActivator(LogicalKeyboardKey.f5): () =>
                ref.read(bootstrapProvider).engine?.syncNow(),
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(context).maybePop(),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              // Scaffold's appBar slot wants a PreferredSizeWidget, which
              // GlassPanel is not — so the panel is wrapped in a fixed-height slot
              // that matches the AppBar's own toolbar below.
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: GlassPanel(
                  // The top bar runs edge to edge, so it keeps square corners: a
                  // rounded radius would let the canvas show through at the window
                  // corner. GlassPanel supplies the translucent fill and hairline;
                  // the AppBar below stays transparent (see the app bar theme).
                  borderRadius: BorderRadius.zero,
                  child: AppBar(
                    titleSpacing: StarSpace.md,
                    toolbarHeight: 64,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'STAR PARIS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          current.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      if (useRail)
                        SizedBox(
                          key: anchors.search,
                          width: 340,
                          child: InkWell(
                            onTap: () => showTrackSheet(context),
                            borderRadius: BorderRadius.circular(
                              StarRadius.field,
                            ),
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: StarSpace.md,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(
                                  StarRadius.field,
                                ),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.search,
                                    size: 18,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: StarSpace.sm),
                                  Expanded(
                                    child: Text(
                                      'Job, invoice, phone or customer',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  // A key-cap, not a label: the shortcut should read as
                                  // a keyboard command, not a feature name.
                                  const ShortcutChip(label: 'Ctrl K'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: StarSpace.md),
                      SyncStatusChip(key: anchors.sync),
                      if (useRail) ...<Widget>[
                        // F5 is a keyboard shortcut, so its key-cap is a desktop
                        // affordance — like the Ctrl K hint, it stays off the phone bar.
                        const SizedBox(width: StarSpace.xs),
                        const ShortcutChip(label: 'F5'),
                      ],
                      const SizedBox(width: StarSpace.sm),
                      PopupMenuButton<String>(
                        key: anchors.menu,
                        tooltip: session.name,
                        icon: CircleAvatar(
                          radius: 15,
                          backgroundColor: StarColors.petrol,
                          child: Text(
                            session.name.characters.first.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        onSelected: (value) async {
                          if (value == 'till') {
                            await showTillSheet(context);
                            return;
                          }
                          if (value == 'theme') {
                            ref.read(themeModeProvider.notifier).toggle();
                            return;
                          }
                          if (value == 'log') {
                            await showLogSheet(context);
                            return;
                          }
                          if (value == 'audit') {
                            await openAuditLog(context);
                            return;
                          }
                          if (value == 'diagnostics') {
                            await showDiagnosticsSheet(context);
                            return;
                          }
                          if (value == 'sectionTour') {
                            ref
                                .read(sectionTourRequestProvider.notifier)
                                .state = ref.read(activeSectionProvider);
                            return;
                          }
                          if (value == 'tour') {
                            ref.read(appTourProvider.notifier).start();
                            return;
                          }
                          if (value == 'signout') {
                            await ref.read(sessionProvider.notifier).signOut();
                          }
                          if (value == 'lang') {
                            ref.read(localeProvider.notifier).toggle();
                          }
                        },
                        itemBuilder: (context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Text('${session.name} · ${session.role}'),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'till',
                            child: Text(t('menu.till')),
                          ),
                          PopupMenuItem<String>(
                            value: 'theme',
                            child: Text(
                              // The label names the mode one click away, matching
                              // the old light/dark toggle's convention of showing
                              // the target rather than the current state.
                              switch (ref.watch(themeModeProvider)) {
                                ThemeMode.dark => t('menu.themeSystem'),
                                ThemeMode.light => t('menu.themeDark'),
                                ThemeMode.system => t('menu.themeLight'),
                              },
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'log',
                            child: Text(t('menu.log')),
                          ),
                          // The strings table is shared and this change does not own
                          // it, so the label stays a literal until `menu.audit` exists
                          // there; an untranslated key would render as the key itself.
                          if (ref.watch(canViewAuditProvider))
                            const PopupMenuItem<String>(
                              value: 'audit',
                              child: Text('Audit log'),
                            ),
                          PopupMenuItem<String>(
                            value: 'diagnostics',
                            child: Text(t('menu.diagnostics')),
                          ),
                          PopupMenuItem<String>(
                            value: 'sectionTour',
                            child: Text(t('menu.sectionTour')),
                          ),
                          PopupMenuItem<String>(
                            value: 'tour',
                            child: Text(t('menu.tour')),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'lang',
                            child: Text(
                              ref.watch(localeProvider)?.languageCode == 'ar'
                                  ? 'English interface'
                                  : 'عربي — Arabic layout',
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'signout',
                            child: Text(t('menu.signout')),
                          ),
                        ],
                      ),
                      const SizedBox(width: StarSpace.sm),
                    ],
                  ),
                ),
              ),
              body: useRail
                  ? Row(
                      children: <Widget>[
                        KeyedSubtree(
                          key: anchors.rail,
                          child: _Rail(
                            work: work,
                            people: people,
                            business: business,
                            selected: index,
                            extended: wide,
                            onSelect: _select,
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: body),
                      ],
                    )
                  : body,
              bottomNavigationBar: useRail
                  ? null
                  : NavigationBar(
                      selectedIndex: _bottomIndex(index, work, people),
                      onDestinationSelected: (position) {
                        if (position < work.length) {
                          _select(work[position].page);
                        } else if (position == work.length) {
                          _select(people.first.page);
                        } else {
                          _showMore(context, business);
                        }
                      },
                      destinations: <Widget>[
                        for (final destination in work)
                          NavigationDestination(
                            icon: Icon(destination.icon),
                            selectedIcon: Icon(destination.selectedIcon),
                            label: destination.label,
                          ),
                        NavigationDestination(
                          icon: Icon(people.first.icon),
                          selectedIcon: Icon(people.first.selectedIcon),
                          label: people.first.label,
                        ),
                        const NavigationDestination(
                          icon: Icon(Icons.more_horiz),
                          selectedIcon: Icon(Icons.more_horiz),
                          label: 'More',
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const AppTourOverlay(),
      ],
    );
  }

  /// With a bottom bar, "More" is the last position and is never selected.
  static int _bottomIndex(int index, List<_Dest> work, List<_Dest> people) {
    for (var i = 0; i < work.length; i++) {
      if (work[i].page == index) return i;
    }
    return people.first.page == index ? work.length : work.length + 1;
  }

  void _showMore(BuildContext context, List<_Dest> business) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.point_of_sale_outlined),
              title: const Text('Cash drawer'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showTillSheet(context);
              },
            ),
            for (final destination in business)
              ListTile(
                leading: Icon(destination.icon),
                title: Text(destination.label),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _select(destination.page);
                },
              ),
            ListTile(
              leading: const Icon(Icons.sync_problem_outlined),
              title: const Text('Sync diagnostics'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showDiagnosticsSheet(context);
              },
            ),
            const SizedBox(height: StarSpace.sm),
          ],
        ),
      ),
    );
  }
}

/// The rail: three labelled groups instead of six flat icons.
///
/// Grouping is not decoration — it tells a new clerk that Prices and Reports
/// belong to the owner, and that a Customer is a different kind of thing from an
/// Order.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.work,
    required this.people,
    required this.business,
    required this.selected,
    required this.extended,
    required this.onSelect,
  });

  final List<_Dest> work;
  final List<_Dest> people;
  final List<_Dest> business;
  final int selected;
  final bool extended;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassPanel(
      // The rail is a full-height strip flush against the window edge, so it
      // keeps square corners. The translucent fill, blur and separating
      // hairline all come from GlassPanel now; the old hand-drawn surface and
      // right border are gone, not re-added on top.
      borderRadius: BorderRadius.zero,
      child: SizedBox(
        width: extended ? 224 : 84,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: StarSpace.md),
            if (extended)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  StarSpace.lg,
                  StarSpace.sm,
                  StarSpace.lg,
                  StarSpace.lg,
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.local_print_shop_outlined,
                      color: StarColors.petrol,
                    ),
                    const SizedBox(width: StarSpace.sm),
                    Expanded(
                      child: Text(
                        'Star Paris',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _group(context, 'WORK', work),
            _group(context, 'PEOPLE', people),
            if (business.isNotEmpty) _group(context, 'BUSINESS', business),
            const Spacer(),
            if (extended)
              Padding(
                padding: const EdgeInsets.all(StarSpace.md),
                child: Text(
                  'Ctrl K search · Ctrl N new order · F5 sync',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _group(BuildContext context, String label, List<_Dest> items) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (extended)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StarSpace.lg,
              StarSpace.md,
              StarSpace.lg,
              StarSpace.xs,
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          const SizedBox(height: StarSpace.md),
        for (final destination in items)
          _RailItem(
            destination: destination,
            selected: destination.page == selected,
            extended: extended,
            onTap: () => onSelect(destination.page),
          ),
      ],
    );
  }
}

class _RailItem extends StatefulWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final _Dest destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHover(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destination = widget.destination;
    final selected = widget.selected;
    final extended = widget.extended;
    final foreground = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    // The same pointer rhythm as PressableCard — hover tints and lifts, press
    // settles — but hand-rolled here: a rail item has its own selected fill
    // and grouped layout, so the shared card widget cannot wrap it without
    // taking over the selection styling.
    final baseColor = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.10)
        : Colors.transparent;
    final color = _hovered
        ? Color.alphaBlend(
            theme.colorScheme.primary.withValues(alpha: 0.04),
            baseColor,
          )
        : baseColor;
    final boxShadow = _hovered
        ? <BoxShadow>[
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ]
        : const <BoxShadow>[];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: StarSpace.sm,
        vertical: 2,
      ),
      child: MouseRegion(
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        child: AnimatedContainer(
          duration: StarMotion.fast,
          curve: StarMotion.easeOut,
          transform: _pressed
              ? (Matrix4.identity()..scaleByDouble(0.985, 0.985, 0.985, 1.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(StarRadius.field),
            boxShadow: boxShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) {
                if (_pressed != value) setState(() => _pressed = value);
              },
              borderRadius: BorderRadius.circular(StarRadius.field),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: extended ? StarSpace.md : 0,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: extended
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      size: 20,
                      color: foreground,
                    ),
                    if (extended) ...<Widget>[
                      const SizedBox(width: StarSpace.md),
                      Expanded(
                        child: Text(
                          destination.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: foreground,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The sync chip, wired to the engine and the outbox.
class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncStateProvider).value;
    final pending = ref.watch(pendingCountProvider).value ?? 0;
    final phase = sync?.phase ?? SyncPhase.idle;

    final chipState = switch (phase) {
      SyncPhase.syncing => SyncChipState.syncing,
      SyncPhase.offline => SyncChipState.offline,
      SyncPhase.attention => SyncChipState.attention,
      SyncPhase.synced => SyncChipState.synced,
      SyncPhase.idle =>
        pending > 0 ? SyncChipState.offline : SyncChipState.synced,
    };

    return SyncChip(
      state: chipState,
      pendingChanges: pending,
      onTap: () => showDiagnosticsSheet(context),
    );
  }
}
