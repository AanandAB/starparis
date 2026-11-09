import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_domain/starparis_domain.dart';

import '../app_config.dart';
import '../providers.dart';
import '../sales/reports_service.dart';
import '../tour/section_tour.dart';

/// VAT for a month and who owes what.
///
/// Unlike every other screen, these numbers come from the server: a VAT return
/// and an ageing list span every branch and every device, so they cannot be
/// answered from one tablet's local database. The screen says so instead of
/// pretending to be offline-capable.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();

  /// The first-visit guide for the Reports screen.
  static const List<TourStep> tourSteps = <TourStep>[
    TourStep(
      icon: Icons.insights_outlined,
      title: 'Reports',
      body: 'Sales, jobs and payments, over any date range you choose.',
    ),
    TourStep(
      anchor: 'header',
      icon: Icons.calendar_month_outlined,
      title: 'Pick and export',
      body: 'Choose a report and a range, then export it.',
    ),
  ];

  /// Resolves an anchor name to the element it spotlights.
  static GlobalKey? tourAnchorFor(String? name) => switch (name) {
        'header' => const GlobalObjectKey('reports-header'),
        _ => null,
      };
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<(VatSummary, AgeingReport, TillHistory)> _report = _load();
  late Future<ExpenseSummary> _purchases = _loadPurchases();

  /// Purchases load separately: a failure there (an officer without access,
  /// say) must not blank the VAT figures above it.
  Future<ExpenseSummary> _loadPurchases() async {
    final bootstrap = ref.read(bootstrapProvider);
    final service = ReportsService(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: bootstrap.auth.accessToken,
    );
    try {
      return await service.expenses(
        from: DateTime(_month.year, _month.month),
        to: DateTime(_month.year, _month.month + 1),
      );
    } finally {
      service.dispose();
    }
  }

  Future<(VatSummary, AgeingReport, TillHistory)> _load() async {
    final bootstrap = ref.read(bootstrapProvider);
    final service = ReportsService(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: bootstrap.auth.accessToken,
    );
    try {
      final from = DateTime(_month.year, _month.month);
      final to = DateTime(_month.year, _month.month + 1);
      final vat = await service.vat(from: from, to: to);
      final ageing = await service.ageing();
      final tills = await service.tills(from: from, to: to);
      return (vat, ageing, tills);
    } finally {
      service.dispose();
    }
  }

  void _move(int months) {
    setState(() {
      _month = DateTime(_month.year, _month.month + months);
      _report = _load();
      _purchases = _loadPurchases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<(VatSummary, AgeingReport, TillHistory)>(
      future: _report,
      builder: (context, snapshot) {
        return ListView(
          padding: const EdgeInsets.all(StarSpace.lg),
          children: <Widget>[
            ScreenHeader(
              key: const GlobalObjectKey('reports-header'),
              title: 'Reports',
              subtitle: 'Read from the server — these figures cover every branch and need a connection.',
              actions: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      tooltip: 'Previous month',
                      onPressed: () => _move(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      _monthLabel(_month),
                      style: theme.textTheme.titleMedium,
                    ),
                    IconButton(
                      tooltip: 'Next month',
                      onPressed: () => _move(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _report = _load();
                    _purchases = _loadPurchases();
                  }),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.all(StarSpace.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError)
              _ErrorCard(message: '${snapshot.error}')
            else ...<Widget>[
              _VatSection(summary: snapshot.data!.$1),
              const SizedBox(height: StarSpace.xl),
              _AgeingSection(report: snapshot.data!.$2),
              const SizedBox(height: StarSpace.xl),
              _TillsSection(history: snapshot.data!.$3),
              const SizedBox(height: StarSpace.xl),
              _PurchasesSection(purchases: _purchases),
            ],
          ],
        );
      },
    );
  }

  static String _monthLabel(DateTime month) {
    const names = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }
}

class _VatSection extends StatelessWidget {
  const _VatSection({required this.summary});

  final VatSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('VAT', style: theme.textTheme.titleMedium),
        const SizedBox(height: StarSpace.md),
        Wrap(
          spacing: StarSpace.md,
          runSpacing: StarSpace.md,
          children: <Widget>[
            _MoneyCard(
              label: 'Sales excl. VAT',
              fils: summary.salesNetFils,
              caption: '${summary.invoiceCount} invoices',
            ),
            _MoneyCard(
              label: 'Output VAT',
              fils: summary.outputVatFils,
              caption: 'charged on those invoices',
            ),
            _MoneyCard(
              label: 'Credits',
              fils: summary.creditedVatFils,
              caption: '${summary.creditNoteCount} credit notes',
            ),
            _MoneyCard(
              label: 'VAT due',
              fils: summary.netVatDueFils,
              caption: 'output less credits',
              tone: StarColors.petrol,
            ),
            _MoneyCard(
              label: 'Collected',
              fils: summary.collectedFils,
              caption: _methods(summary.collectedByMethod),
            ),
            if (summary.refundedFils > 0)
              _MoneyCard(
                label: 'Refunded',
                fils: summary.refundedFils,
                caption: 'cash out',
                tone: StarColors.statusProblem,
              ),
          ],
        ),
      ],
    );
  }

  static String _methods(Map<String, int> byMethod) {
    if (byMethod.isEmpty) return 'nothing received';
    return byMethod.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${entry.key} ${Fils(entry.value).aedText}')
        .join(' · ');
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({
    required this.label,
    required this.fils,
    required this.caption,
    this.tone,
  });

  final String label;
  final int fils;
  final String caption;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 230,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(StarSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: StarSpace.xs),
              Text(
                Fils(fils).aedLabel,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: tone ?? theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: StarSpace.xs),
              Text(
                caption,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeingSection extends StatelessWidget {
  const _AgeingSection({required this.report});

  final AgeingReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('Outstanding by age', style: theme.textTheme.titleMedium),
            const SizedBox(width: StarSpace.md),
            Text(
              '${Fils(report.totals.totalFils).aedLabel} across '
              '${report.rows.length} customer${report.rows.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: StarSpace.sm),
        if (report.rows.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(StarSpace.lg),
              child: Text(
                'Nothing outstanding. Every issued invoice is paid or credited.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: StarSpace.xl,
                headingRowHeight: 40,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 44,
                columns: const <DataColumn>[
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Current'), numeric: true),
                  DataColumn(label: Text('31–60'), numeric: true),
                  DataColumn(label: Text('61–90'), numeric: true),
                  DataColumn(label: Text('90+'), numeric: true),
                  DataColumn(label: Text('Total'), numeric: true),
                ],
                rows: <DataRow>[
                  for (final row in report.rows)
                    DataRow(
                      cells: <DataCell>[
                        DataCell(
                          SizedBox(
                            width: 200,
                            child: Text(
                              row.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(_money(row.currentFils)),
                        DataCell(_money(row.days3160Fils)),
                        DataCell(_money(row.days6190Fils)),
                        DataCell(_money(row.over90Fils, alarm: true)),
                        DataCell(
                          Text(
                            Fils(row.totalFils).aedText,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  DataRow(
                    color: WidgetStatePropertyAll<Color>(
                      theme.colorScheme.surfaceContainerHighest,
                    ),
                    cells: <DataCell>[
                      const DataCell(
                        Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(_money(report.totals.currentFils)),
                      DataCell(_money(report.totals.days3160Fils)),
                      DataCell(_money(report.totals.days6190Fils)),
                      DataCell(_money(report.totals.over90Fils, alarm: true)),
                      DataCell(
                        Text(
                          Fils(report.totals.totalFils).aedText,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// A zero is quieter than a number: an empty bucket should not draw the eye.
  static Widget _money(int fils, {bool alarm = false}) => Text(
    fils == 0 ? '–' : Fils(fils).aedText,
    style: alarm && fils > 0
        ? const TextStyle(color: StarColors.statusProblem)
        : null,
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(StarSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.cloud_off, size: 18),
                const SizedBox(width: StarSpace.sm),
                Text(
                  'Could not read the reports',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: StarSpace.sm),
            Text(message, style: theme.textTheme.bodySmall),
            const SizedBox(height: StarSpace.sm),
            Text(
              'These figures come from the server. Everything else on this device still works offline.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The shifts behind the counter this month.
///
/// A variance is not a number to hide: every short drawer gets a person and a
/// time against it, so the owner can ask the right question instead of
/// distrusting the till.
class _TillsSection extends StatelessWidget {
  const _TillsSection({required this.history});

  final TillHistory history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final closed = history.shifts.where((shift) => shift.status == 'closed');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Cash drawer', style: theme.textTheme.titleMedium),
        const SizedBox(height: StarSpace.xs),
        Text(
          closed.isEmpty
              ? 'No shift was closed this month.'
              : '${closed.length} ${closed.length == 1 ? 'shift' : 'shifts'} closed. '
                    'A variance is what the drawer was over or short against '
                    'what the server expected.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: StarSpace.md),
        if (history.shifts.isEmpty)
          const EmptyState(
            icon: Icons.point_of_sale_outlined,
            title: 'Nothing in the drawer yet',
            message:
                'Open the till at the counter and shifts will show up here.',
          )
        else
          Card(
            child: Column(
              children: <Widget>[
                for (final shift in history.shifts) _TillRow(shift: shift),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StarSpace.md,
                    vertical: StarSpace.sm,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          history.varianceFils == 0
                              ? 'Every shift balanced.'
                              : 'Over all: ${Fils(history.varianceFils).aedLabel}',
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      if (history.shortFils != 0)
                        Text(
                          'Short ${Fils(history.shortFils.abs()).aedLabel}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TillRow extends StatelessWidget {
  const _TillRow({required this.shift});

  final TillShift shift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opened = shift.openedAt.toLocal();
    final open = '${opened.day}/${opened.month} ${_hhmm(opened)}';
    final variance = shift.varianceFils ?? 0;

    return ListTile(
      dense: true,
      leading: Icon(
        shift.isShort ? Icons.trending_down : Icons.point_of_sale_outlined,
        size: 18,
        color: shift.isShort ? theme.colorScheme.error : null,
      ),
      title: Text(
        shift.status == 'open' ? '$open — still open' : open,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        <String>[
          if (shift.openedBy != null) 'opened by ${shift.openedBy}',
          if (shift.closedBy != null) 'closed by ${shift.closedBy}',
          if (shift.openingFloatFils > 0)
            'float ${Fils(shift.openingFloatFils).aedLabel}',
        ].join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: shift.expectedFils == null
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  'expected ${Fils(shift.expectedFils!).aedLabel}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  variance == 0
                      ? 'counted exactly'
                      : '${variance > 0 ? 'over' : 'short'} '
                            '${Fils(variance.abs()).aedLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: variance == 0
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
    );
  }

  static String _hhmm(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// What the shop spent, by category.
///
/// The VAT on these receipts is input VAT: already paid, so it comes off what
/// is owed on sales. Showing it here means the owner sees the whole return, not
/// half of it.
class _PurchasesSection extends StatelessWidget {
  const _PurchasesSection({required this.purchases});

  final Future<ExpenseSummary> purchases;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<ExpenseSummary>(
      future: purchases,
      builder: (context, snapshot) {
        final summary = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Purchases', style: theme.textTheme.titleMedium),
            const SizedBox(height: StarSpace.xs),
            Text(
              'Money paid out this month, by category. The VAT on these receipts '
              'is input VAT and comes off the VAT due on sales.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: StarSpace.md),
            if (snapshot.hasError)
              _ErrorCard(message: '${snapshot.error}')
            else if (summary == null)
              const Padding(
                padding: EdgeInsets.all(StarSpace.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (summary.rows.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Nothing paid out this month',
                message: 'Couriers, materials and taxis recorded from the cash drawer appear here.',
              )
            else
              Card(
                child: Column(
                  children: <Widget>[
                    for (final row in summary.rows)
                      ListTile(
                        dense: true,
                        title: Text(row.category),
                        subtitle: Text(
                          row.entries == 1
                              ? '1 entry'
                              : '${row.entries} entries',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              Fils(row.totalFils).aedLabel,
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (row.vatFils > 0)
                              Text(
                                'incl. ${Fils(row.vatFils).aedLabel} VAT',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: StarSpace.md,
                        vertical: StarSpace.sm,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Paid out ${Fils(summary.totalFils).aedLabel}',
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                          Text(
                            summary.vatFils == 0
                                ? 'no VAT on these receipts'
                                : 'input VAT ${Fils(summary.vatFils).aedLabel}',
                            style: theme.textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
