import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_domain/starparis_domain.dart';

import '../app_config.dart';
import '../providers.dart';
import '../sales/reports_service.dart';

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
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<(VatSummary, AgeingReport)> _report = _load();

  Future<(VatSummary, AgeingReport)> _load() async {
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
      return (vat, ageing);
    } finally {
      service.dispose();
    }
  }

  void _move(int months) {
    setState(() {
      _month = DateTime(_month.year, _month.month + months);
      _report = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<(VatSummary, AgeingReport)>(
      future: _report,
      builder: (context, snapshot) {
        return ListView(
          padding: const EdgeInsets.all(StarSpace.lg),
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('Reports', style: theme.textTheme.headlineSmall),
                const SizedBox(width: StarSpace.lg),
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: () => _move(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(_monthLabel(_month), style: theme.textTheme.titleMedium),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: () => _move(1),
                  icon: const Icon(Icons.chevron_right),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _report = _load()),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: StarSpace.xs),
            Text(
              'Read from the server — these figures cover every branch and need a connection.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: StarSpace.lg),
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
