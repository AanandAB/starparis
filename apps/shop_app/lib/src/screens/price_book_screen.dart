import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../providers.dart';
import '../sales/price_book_api.dart';

/// The owner's price book.
///
/// This is the screen that makes design goal #2 true: every rate the shop
/// charges is editable here, with an audit trail and a dry-run preview for bulk
/// changes. Existing orders are untouched — they carry a frozen breakdown — so
/// the warning at the top is a fact, not a disclaimer.
class PriceBookScreen extends ConsumerWidget {
  const PriceBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(allRulesProvider);
    final products = ref.watch(productsProvider).value ?? const <Product>[];
    final version = ref.watch(priceBookVersionProvider).value ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StarSpace.lg,
            StarSpace.lg,
            StarSpace.lg,
            StarSpace.md,
          ),
          child: ScreenHeader(
            title: 'Price book',
            subtitle: 'Version $version · changes apply to new orders only',
            actions: <Widget>[
              OutlinedButton.icon(
                onPressed: () => _showBulkAdjust(context, ref, products),
                icon: const Icon(Icons.percent, size: 18),
                label: const Text('Bulk adjust'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: rules.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Could not read the price book',
              message: '$error',
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return const EmptyState(
                  icon: Icons.price_change_outlined,
                  title: 'No price rules on this device',
                  message: 'Connect once so the price book can download.',
                );
              }
              return ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final rule = rows[index];
                  final product = products
                      .where((candidate) => candidate.id == rule.productId)
                      .firstOrNull;
                  return _RuleRow(
                    rule: rule,
                    productName: product?.nameEn ?? 'All products',
                    onEdit: () => _showEditDialog(context, ref, rule),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    PriceRuleRow rule,
  ) async {
    final result = await showDialog<_RuleEdit>(
      context: context,
      builder: (context) => _EditRuleDialog(rule: rule),
    );
    if (result == null) return;

    final bootstrap = ref.read(bootstrapProvider);
    try {
      await PriceBookApi(
        baseUrl: bootstrap.catalogue.baseUrl,
        tokenProvider: bootstrap.auth.accessToken,
      ).updateRule(
        rule.id,
        rateFils: result.rateFils,
        minChargeFils: result.minChargeFils,
        active: result.active,
      );
      await bootstrap.catalogue.refresh(force: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Price saved. Every device gets it on its next refresh.',
          ),
        ),
      );
    } on PriceBookException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _showBulkAdjust(
    BuildContext context,
    WidgetRef ref,
    List<Product> products,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _BulkAdjustDialog(products: products),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.rule,
    required this.productName,
    required this.onEdit,
  });

  final PriceRuleRow rule;
  final String productName;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(rule.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '$productName · ${rule.phase} · ${rule.basis.replaceAll('_', ' ')}'
        '${rule.active ? '' : ' · inactive'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MoneyText(Fils(rule.rateFils), emphasise: true),
          const SizedBox(width: StarSpace.sm),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Edit rate',
          ),
        ],
      ),
    );
  }
}

class _RuleEdit {
  const _RuleEdit({
    required this.rateFils,
    required this.minChargeFils,
    required this.active,
  });

  final int rateFils;
  final int minChargeFils;
  final bool active;
}

class _EditRuleDialog extends StatefulWidget {
  const _EditRuleDialog({required this.rule});

  final PriceRuleRow rule;

  @override
  State<_EditRuleDialog> createState() => _EditRuleDialogState();
}

class _EditRuleDialogState extends State<_EditRuleDialog> {
  late final TextEditingController _rate = TextEditingController(
    text: Fils(widget.rule.rateFils).aedText,
  );
  late final TextEditingController _minimum = TextEditingController(
    text: Fils(widget.rule.minChargeFils).aedText,
  );
  late bool _active = widget.rule.active;
  String? _error;

  @override
  void dispose() {
    _rate.dispose();
    _minimum.dispose();
    super.dispose();
  }

  void _save() {
    try {
      final rate = Fils.parse(_rate.text);
      final minimum = Fils.parse(_minimum.text);
      Navigator.of(context).pop(
        _RuleEdit(
          rateFils: rate.raw,
          minChargeFils: minimum.raw,
          active: _active,
        ),
      );
    } on FormatException {
      setState(() => _error = 'Enter an amount like 0.80 or 12.50');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.rule.label),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Charged ${widget.rule.basis.replaceAll('_', ' ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: StarSpace.md),
            TextField(
              controller: _rate,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Rate (AED)',
                prefixText: 'AED ',
              ),
            ),
            const SizedBox(height: StarSpace.md),
            TextField(
              controller: _minimum,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Minimum charge (AED)',
                prefixText: 'AED ',
              ),
            ),
            const SizedBox(height: StarSpace.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (value) => setState(() => _active = value),
              title: const Text('Active'),
              subtitle: const Text('Inactive rules are skipped when pricing.'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: StarColors.statusProblem),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _BulkAdjustDialog extends ConsumerStatefulWidget {
  const _BulkAdjustDialog({required this.products});

  final List<Product> products;

  @override
  ConsumerState<_BulkAdjustDialog> createState() => _BulkAdjustDialogState();
}

class _BulkAdjustDialogState extends ConsumerState<_BulkAdjustDialog> {
  final TextEditingController _percent = TextEditingController(text: '5');
  String? _productId;
  BulkResult? _preview;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _percent.dispose();
    super.dispose();
  }

  int? _bps() {
    final value = double.tryParse(_percent.text.trim());
    if (value == null || value.abs() > 200) return null;
    return (value * 100).round();
  }

  Future<void> _run({required bool dryRun}) async {
    final bps = _bps();
    if (bps == null) {
      setState(() => _error = 'Enter a percentage between -200 and 200.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final bootstrap = ref.read(bootstrapProvider);
    try {
      final result = await PriceBookApi(
        baseUrl: bootstrap.catalogue.baseUrl,
        tokenProvider: bootstrap.auth.accessToken,
      ).bulkAdjust(productId: _productId, percentBps: bps, dryRun: dryRun);

      if (dryRun) {
        setState(() => _preview = result);
      } else {
        await bootstrap.catalogue.refresh(force: true);
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Adjusted ${result.changes.length} prices.')),
        );
      }
    } on PriceBookException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _preview;

    return AlertDialog(
      title: const Text('Bulk price adjust'),
      content: SizedBox(
        width: dialogWidth(context, max: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Raises or lowers every affected rate by a percentage. Preview first — '
              'the arithmetic is the same as the real run.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: StarSpace.md),
            DropdownButtonFormField<String?>(
              initialValue: _productId,
              decoration: const InputDecoration(labelText: 'Scope'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All products'),
                ),
                for (final product in widget.products)
                  DropdownMenuItem<String?>(
                    value: product.id,
                    child: Text(product.nameEn),
                  ),
              ],
              onChanged: (value) => setState(() {
                _productId = value;
                _preview = null;
              }),
            ),
            const SizedBox(height: StarSpace.md),
            TextField(
              controller: _percent,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Change',
                suffixText: '%',
                helperText: 'Use a negative number to lower prices.',
              ),
              onChanged: (_) => setState(() => _preview = null),
            ),
            if (preview != null) ...<Widget>[
              const SizedBox(height: StarSpace.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    for (final change in preview.changes)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                change.label,
                                style: theme.textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${Fils(change.rateFils).aedText} → '
                              '${Fils(change.newRateFils).aedText}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: StarSpace.sm),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: StarColors.statusProblem,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => _run(dryRun: true),
          child: const Text('Preview'),
        ),
        FilledButton(
          onPressed: _busy || preview == null
              ? null
              : () => _run(dryRun: false),
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Apply'),
        ),
      ],
    );
  }
}
