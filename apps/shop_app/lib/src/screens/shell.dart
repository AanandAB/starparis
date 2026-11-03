import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../providers.dart';
import 'board_screen.dart';
import 'customers_screen.dart';
import 'diagnostics_sheet.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'price_book_screen.dart';
import 'reports_screen.dart';

/// The frame every screen lives in: navigation, the sync chip, and the user
/// menu. Three layouts — bottom bar on a phone, rail on a tablet, labelled rail
/// with a wider content area on Windows.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final index = ref.watch(shellTabProvider);
    void select(int next) => ref.read(shellTabProvider.notifier).select(next);

    final pages = <Widget>[
      const HomeScreen(),
      const CustomersScreen(),
      const OrdersScreen(),
      const ProductionScreen(),
      if (ref.watch(canEditPricesProvider)) const PriceBookScreen(),
      if (ref.watch(canViewReportsProvider)) const ReportsScreen(),
    ];

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Customers',
      ),
      const NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Orders',
      ),
      const NavigationDestination(
        icon: Icon(Icons.view_kanban_outlined),
        selectedIcon: Icon(Icons.view_kanban),
        label: 'Production',
      ),
      if (ref.watch(canEditPricesProvider))
        const NavigationDestination(
          icon: Icon(Icons.price_change_outlined),
          selectedIcon: Icon(Icons.price_change),
          label: 'Prices',
        ),
      if (ref.watch(canViewReportsProvider))
        const NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: 'Reports',
        ),
    ];

    final width = MediaQuery.sizeOf(context).width;
    final useRail = Platform.isWindows || Platform.isMacOS || Platform.isLinux
        ? true
        : width >= StarBreakpoints.medium;

    final body = IndexedStack(index: index, children: pages);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: StarSpace.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Star Paris',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            Text(session.homeTitle),
          ],
        ),
        actions: <Widget>[
          const Padding(
            padding: EdgeInsets.only(right: StarSpace.sm),
            child: SyncStatusChip(),
          ),
          PopupMenuButton<String>(
            tooltip: session.name,
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: StarColors.petrol,
              child: Text(
                session.name.characters.first.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            onSelected: (value) async {
              if (value == 'diagnostics') {
                await showDiagnosticsSheet(context);
                return;
              }
              if (value == 'signout') {
                await ref.read(sessionProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                child: Text('${session.name} · ${session.role}'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'diagnostics',
                child: Text('Sync diagnostics'),
              ),
              const PopupMenuItem<String>(
                value: 'signout',
                child: Text('Sign out'),
              ),
            ],
          ),
          const SizedBox(width: StarSpace.sm),
        ],
      ),
      body: useRail
          ? Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: select,
                  labelType: width > StarBreakpoints.medium
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.selected,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: StarSpace.md),
                    child: Icon(Icons.local_print_shop_outlined),
                  ),
                  destinations: <NavigationRailDestination>[
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: destination.icon,
                        selectedIcon: destination.selectedIcon,
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: select,
              destinations: destinations,
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
