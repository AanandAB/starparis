import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../providers.dart';
import '../theme_provider.dart';
import '../sales/till_sheet.dart';
import 'board_screen.dart';
import 'catalogue_screen.dart';
import 'customers_screen.dart';
import 'diagnostics_sheet.dart';
import 'home_screen.dart';
import 'log_sheet.dart';
import 'orders_screen.dart';
import 'price_book_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'staff_screen.dart';
import 'track_sheet.dart';
import 'vendors_screen.dart';

/// One place to go, and which page it shows.
class _Dest {
  const _Dest(this.label, this.icon, this.selectedIcon, this.page);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int page;
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
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final index = ref.watch(shellTabProvider);
    final t = ref.watch(stringsProvider);
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
      ),
      _Dest(
        t('nav.orders'),
        Icons.receipt_long_outlined,
        Icons.receipt_long,
        HomeTabs.orders,
      ),
      _Dest(
        t('nav.production'),
        Icons.view_kanban_outlined,
        Icons.view_kanban,
        HomeTabs.production,
      ),
    ];
    final people = <_Dest>[
      _Dest(
        t('nav.customers'),
        Icons.people_outline,
        Icons.people,
        HomeTabs.customers,
      ),
    ];

    // The pages after Production are optional, one per role, so their indices
    // are counted rather than hard-coded: a manager has no Prices screen, and a
    // fixed index would then point at the wrong page.
    var nextPage = 4;
    final business = <_Dest>[];
    final optionalPages = <Widget>[];

    if (ref.watch(canEditPricesProvider)) {
      business.add(
        _Dest(
          t('nav.catalogue'),
          Icons.inventory_2_outlined,
          Icons.inventory_2,
          nextPage++,
        ),
      );
      optionalPages.add(const CatalogueScreen());
    }
    if (ref.watch(canEditPricesProvider)) {
      business.add(
        _Dest(
          t('nav.prices'),
          Icons.price_change_outlined,
          Icons.price_change,
          nextPage++,
        ),
      );
      optionalPages.add(const PriceBookScreen());
    }
    if (ref.watch(canViewReportsProvider)) {
      business.add(
        _Dest(
          t('nav.reports'),
          Icons.insights_outlined,
          Icons.insights,
          nextPage++,
        ),
      );
      optionalPages.add(const ReportsScreen());
    }
    if (ref.watch(canManageStaffProvider)) {
      business.add(
        _Dest(t('nav.staff'), Icons.badge_outlined, Icons.badge, nextPage++),
      );
      optionalPages.add(const StaffScreen());
    }
    if (ref.watch(canManageStaffProvider)) {
      // Settings sits last: it is the rarest thing an owner opens.
      business.add(
        _Dest(
          t('nav.settings'),
          Icons.settings_outlined,
          Icons.settings,
          nextPage++,
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
        ),
      );
      optionalPages.add(const VendorsScreen());
    }

    final pages = <Widget>[
      const HomeScreen(),
      const CustomersScreen(),
      const OrdersScreen(),
      const ProductionScreen(),
      ...optionalPages,
    ];

    final all = <_Dest>[...work, ...people, ...business];
    final current = all.firstWhere(
      (destination) => destination.page == index,
      orElse: () => all.first,
    );

    final body = IndexedStack(index: index, children: pages);

    // Global keys: a counter works at speed, and three of the most common
    // actions should not need the mouse.
    return CallbackShortcuts(
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
          appBar: AppBar(
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
                  width: 340,
                  child: InkWell(
                    onTap: () => showTrackSheet(context),
                    borderRadius: BorderRadius.circular(StarRadius.field),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(
                        horizontal: StarSpace.md,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(StarRadius.field),
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
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            'Ctrl K',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: StarSpace.md),
              const SyncStatusChip(),
              const SizedBox(width: StarSpace.sm),
              PopupMenuButton<String>(
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
                  if (value == 'diagnostics') {
                    await showDiagnosticsSheet(context);
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
                      ref.watch(themeModeProvider) == ThemeMode.dark
                          ? t('menu.themeLight')
                          : t('menu.themeDark'),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'log',
                    child: Text(t('menu.log')),
                  ),
                  PopupMenuItem<String>(
                    value: 'diagnostics',
                    child: Text(t('menu.diagnostics')),
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
          body: useRail
              ? Row(
                  children: <Widget>[
                    _Rail(
                      work: work,
                      people: people,
                      business: business,
                      selected: index,
                      extended: wide,
                      onSelect: _select,
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

    return Container(
      width: extended ? 224 : 84,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
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

class _RailItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: StarSpace.sm,
        vertical: 2,
      ),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(StarRadius.field),
        child: InkWell(
          onTap: onTap,
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
