import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../app_config.dart';
import '../providers.dart';
import '../sales/catalogue_admin_service.dart';

/// Production setup — the paper, presses and finishing steps the price engine
/// reads from the catalogue.
///
/// Three tabs, one per reference table. Machines and operations list from the
/// local mirror (they arrive with every catalogue refresh); materials list from
/// the server, because the local Material model is a subset of the row — the
/// sheet size and supplier that the owner edits live only on the server. Every
/// write needs the network, so a tablet that has been offline for a week cannot
/// invent a machine every other counter would then price with.
class ProductionSetupScreen extends ConsumerStatefulWidget {
  const ProductionSetupScreen({super.key});

  @override
  ConsumerState<ProductionSetupScreen> createState() =>
      _ProductionSetupScreenState();
}

class _ProductionSetupScreenState extends ConsumerState<ProductionSetupScreen> {
  int _tab = 0;
  late Future<List<Map<String, Object?>>> _materialsFuture;

  @override
  void initState() {
    super.initState();
    _materialsFuture = _loadMaterials();
  }

  String get _addLabel => switch (_tab) {
    0 => 'Add material',
    1 => 'Add machine',
    _ => 'Add operation',
  };

  CatalogueAdminService _service() {
    final bootstrap = ref.read(bootstrapProvider);
    return CatalogueAdminService(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: bootstrap.auth.accessToken,
    );
  }

  Future<List<Map<String, Object?>>> _loadMaterials() async {
    final service = _service();
    try {
      return await service.listMaterials();
    } finally {
      service.dispose();
    }
  }

  /// Refreshes the local reference data (machines, operations) and re-pulls the
  /// server material list, so the editor never shows a stale row after a write.
  Future<void> _refresh() async {
    await ref.read(bootstrapProvider).catalogue.refresh(force: true);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    switch (_tab) {
      case 0:
        final draft = await showDialog<_MaterialDraft>(
          context: context,
          builder: (_) => const _MaterialDialog(),
        );
        if (draft == null || !mounted) return;
        final service = _service();
        try {
          await service.createMaterial(
            code: draft.code,
            name: draft.name,
            type: draft.type,
            gsm: draft.gsm,
            sheetWidthMm: draft.sheetWidthMm,
            sheetHeightMm: draft.sheetHeightMm,
            costPerSheetFils: draft.costPerSheetFils,
            supplierId: draft.supplierId,
          );
          await _refresh();
          setState(() => _materialsFuture = _loadMaterials());
          _snack('${draft.name} added.');
        } catch (error) {
          _snack('$error');
        } finally {
          service.dispose();
        }
      case 1:
        final draft = await showDialog<_MachineDraft>(
          context: context,
          builder: (_) => const _MachineDialog(),
        );
        if (draft == null || !mounted) return;
        final service = _service();
        try {
          await service.createMachine(
            name: draft.name,
            type: draft.type,
            hourlyRateFils: draft.hourlyRateFils,
            setupMinutes: draft.setupMinutes,
            sheetsPerHour: draft.sheetsPerHour,
            plateCostFils: draft.plateCostFils,
            clickFils: draft.clickFils,
          );
          await _refresh();
          _snack('${draft.name} added.');
        } catch (error) {
          _snack('$error');
        } finally {
          service.dispose();
        }
      default:
        final draft = await showDialog<_OperationDraft>(
          context: context,
          builder: (_) => const _OperationDialog(),
        );
        if (draft == null || !mounted) return;
        final service = _service();
        try {
          await service.createOperation(
            code: draft.code,
            nameEn: draft.nameEn,
            phase: draft.phase,
            basis: draft.basis,
            rateFils: draft.rateFils,
            setupFils: draft.setupFils,
            wasteBps: draft.wasteBps,
            minChargeFils: draft.minChargeFils,
          );
          await _refresh();
          _snack('${draft.nameEn} added.');
        } catch (error) {
          _snack('$error');
        } finally {
          service.dispose();
        }
    }
  }

  Future<void> _editMaterial(Map<String, Object?> row) async {
    final draft = await showDialog<_MaterialDraft>(
      context: context,
      builder: (_) => _MaterialDialog(existing: row),
    );
    if (draft == null || !mounted) return;
    final service = _service();
    try {
      await service.updateMaterial(
        row['id']! as String,
        name: draft.name,
        type: draft.type,
        gsm: draft.gsm,
        sheetWidthMm: draft.sheetWidthMm,
        sheetHeightMm: draft.sheetHeightMm,
        costPerSheetFils: draft.costPerSheetFils,
        supplierId: draft.supplierId,
      );
      await _refresh();
      setState(() => _materialsFuture = _loadMaterials());
      _snack('Saved.');
    } catch (error) {
      _snack('$error');
    } finally {
      service.dispose();
    }
  }

  Future<void> _deleteMaterial(Map<String, Object?> row) async {
    if (!await _confirmDelete(row['name'] as String? ?? 'material')) return;
    final service = _service();
    try {
      await service.deleteMaterial(row['id']! as String);
      await _refresh();
      setState(() => _materialsFuture = _loadMaterials());
      _snack('Removed.');
    } catch (error) {
      _snack('$error');
    } finally {
      service.dispose();
    }
  }

  Future<void> _editMachine(Machine machine) async {
    final draft = await showDialog<_MachineDraft>(
      context: context,
      builder: (_) => _MachineDialog(existing: machine),
    );
    if (draft == null || !mounted) return;
    final service = _service();
    try {
      await service.updateMachine(
        machine.id,
        name: draft.name,
        type: draft.type,
        hourlyRateFils: draft.hourlyRateFils,
        setupMinutes: draft.setupMinutes,
        sheetsPerHour: draft.sheetsPerHour,
        plateCostFils: draft.plateCostFils,
        clickFils: draft.clickFils,
      );
      await _refresh();
      _snack('Saved.');
    } catch (error) {
      _snack('$error');
    } finally {
      service.dispose();
    }
  }

  Future<void> _deleteMachine(Machine machine) async {
    if (!await _confirmDelete(machine.name)) return;
    final service = _service();
    try {
      await service.deleteMachine(machine.id);
      await _refresh();
      _snack('Removed.');
    } catch (error) {
      _snack('$error');
    } finally {
      service.dispose();
    }
  }

  Future<void> _editOperation(Operation operation) async {
    final draft = await showDialog<_OperationDraft>(
      context: context,
      builder: (_) => _OperationDialog(existing: operation),
    );
    if (draft == null || !mounted) return;
    final service = _service();
    try {
      await service.updateOperation(
        operation.id,
        nameEn: draft.nameEn,
        phase: draft.phase,
        basis: draft.basis,
        rateFils: draft.rateFils,
        setupFils: draft.setupFils,
        wasteBps: draft.wasteBps,
        minChargeFils: draft.minChargeFils,
      );
      await _refresh();
      _snack('Saved.');
    } catch (error) {
      _snack('$error');
    } finally {
      service.dispose();
    }
  }

  Future<void> _deleteOperation(Operation operation) async {
    if (!await _confirmDelete(operation.nameEn)) return;
    final service = _service();
    try {
      await service.deleteOperation(operation.id);
      await _refresh();
      _snack('Removed.');
    } catch (error) {
      _snack('$error');
    } finally {
      service.dispose();
    }
  }

  Future<bool> _confirmDelete(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove $name?'),
        content: const Text(
          'It is hidden, not erased — every device stops offering it, and the '
          'change is recorded in the audit trail.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(StarSpace.lg),
          child: ScreenHeader(
            title: 'Production setup',
            subtitle:
                'The paper, presses and finishing steps the price engine reads. '
                'A change here reaches every counter on its next sync.',
            actions: <Widget>[
              FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add, size: 18),
                label: Text(_addLabel),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: StarSpace.lg),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(
                  value: 0,
                  label: Text('Materials'),
                  icon: Icon(Icons.layers_outlined),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text('Machines'),
                  icon: Icon(Icons.print_outlined),
                ),
                ButtonSegment<int>(
                  value: 2,
                  label: Text('Operations'),
                  icon: Icon(Icons.handyman_outlined),
                ),
              ],
              selected: <int>{_tab},
              onSelectionChanged: (selection) =>
                  setState(() => _tab = selection.first),
            ),
          ),
        ),
        const SizedBox(height: StarSpace.md),
        Expanded(
          child: switch (_tab) {
            0 => _MaterialsList(
              future: _materialsFuture,
              onEdit: _editMaterial,
              onDelete: _deleteMaterial,
              onRetry: () => setState(
                () => _materialsFuture = _loadMaterials(),
              ),
            ),
            1 => _MachinesList(onEdit: _editMachine, onDelete: _deleteMachine),
            _ => _OperationsList(
              onEdit: _editOperation,
              onDelete: _deleteOperation,
            ),
          },
        ),
      ],
    );
  }
}

// --- lists -----------------------------------------------------------------

class _MaterialsList extends StatelessWidget {
  const _MaterialsList({
    required this.future,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
  });

  final Future<List<Map<String, Object?>>> future;
  final ValueChanged<Map<String, Object?>> onEdit;
  final ValueChanged<Map<String, Object?>> onDelete;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message:
                'Materials need a connection. Everything else still works '
                'offline.',
            onRetry: onRetry,
          );
        }
        final rows = snapshot.data ?? const <Map<String, Object?>>[];
        if (rows.isEmpty) {
          return const EmptyState(
            icon: Icons.layers_outlined,
            title: 'No paper in the catalogue',
            message:
                'Add the stock you buy: art card, flex, vinyl. Each one carries '
                'its cost per sheet so the price follows the paper.',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            StarSpace.lg,
            0,
            StarSpace.lg,
            StarSpace.xxl,
          ),
          children: <Widget>[
            Card(
              child: Column(
                children: <Widget>[
                  for (var i = 0; i < rows.length; i++) ...<Widget>[
                    if (i > 0) const Divider(height: 1),
                    _row(
                      onTap: () => onEdit(rows[i]),
                      onDelete: () => onDelete(rows[i]),
                      title: rows[i]['name'] as String? ?? '',
                      subtitle: _materialSubtitle(rows[i]),
                      amountFils:
                          (rows[i]['cost_per_sheet_fils'] as num?)?.toInt() ?? 0,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static String _materialSubtitle(Map<String, Object?> row) {
    final parts = <String>[
      if (row['code'] != null) row['code'] as String,
      if (row['type'] != null) row['type'] as String,
      if ((row['gsm'] as num?)?.toInt() != null)
        '${(row['gsm'] as num).toInt()} gsm',
      if ((row['sheet_width_mm'] as num?)?.toInt() != null &&
          (row['sheet_height_mm'] as num?)?.toInt() != null)
        '${(row['sheet_width_mm'] as num).toInt()} × '
            '${(row['sheet_height_mm'] as num).toInt()} mm',
      if (row['supplier_id'] != null) row['supplier_id'] as String,
    ];
    return parts.join(' · ');
  }
}

class _MachinesList extends ConsumerWidget {
  const _MachinesList({required this.onEdit, required this.onDelete});

  final ValueChanged<Machine> onEdit;
  final ValueChanged<Machine> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machines = ref.watch(machinesProvider).value ?? const <Machine>[];
    if (machines.isEmpty) {
      return const EmptyState(
        icon: Icons.print_outlined,
        title: 'No presses yet',
        message:
            'Add each press and its hour rate, setup and click charge so jobs '
            'are priced from the machine they actually run on.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        StarSpace.lg,
        0,
        StarSpace.lg,
        StarSpace.xxl,
      ),
      children: <Widget>[
        Card(
          child: Column(
            children: <Widget>[
              for (var i = 0; i < machines.length; i++) ...<Widget>[
                if (i > 0) const Divider(height: 1),
                _row(
                  onTap: () => onEdit(machines[i]),
                  onDelete: () => onDelete(machines[i]),
                  title: machines[i].name,
                  subtitle: machines[i].type.replaceAll('_', ' '),
                  amountFils: machines[i].clickFils,
                  amountLabel: 'click',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OperationsList extends ConsumerWidget {
  const _OperationsList({required this.onEdit, required this.onDelete});

  final ValueChanged<Operation> onEdit;
  final ValueChanged<Operation> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operations =
        ref.watch(operationsProvider).value ?? const <Operation>[];
    if (operations.isEmpty) {
      return const EmptyState(
        icon: Icons.handyman_outlined,
        title: 'No finishing steps yet',
        message:
            'Add lamination, creasing, binding — each with its basis, rate and '
            'waste. A new step is a row, not a deployment.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        StarSpace.lg,
        0,
        StarSpace.lg,
        StarSpace.xxl,
      ),
      children: <Widget>[
        Card(
          child: Column(
            children: <Widget>[
              for (var i = 0; i < operations.length; i++) ...<Widget>[
                if (i > 0) const Divider(height: 1),
                _row(
                  onTap: () => onEdit(operations[i]),
                  onDelete: () => onDelete(operations[i]),
                  title: operations[i].nameEn,
                  subtitle: operations[i].basis.replaceAll('_', ' '),
                  amountFils: operations[i].rateFils,
                  amountLabel: operations[i].basis.replaceAll('per_', ''),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One editable catalogue row: title, a detail line and the money on the right.
Widget _row({
  required VoidCallback onTap,
  required VoidCallback onDelete,
  required String title,
  required String subtitle,
  required int amountFils,
  String? amountLabel,
}) {
  return ListTile(
    dense: true,
    onTap: onTap,
    leading: const Icon(Icons.edit_outlined, size: 18),
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(
      subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (amountFils > 0)
          Text(
            amountLabel == null
                ? Fils(amountFils).aedLabel
                : '${Fils(amountFils).aedLabel} / $amountLabel',
          ),
        IconButton(
          tooltip: 'Remove',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, size: 18),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StarSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: StarSpace.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: StarSpace.md),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// --- drafts and dialogs ----------------------------------------------------

class _MaterialDraft {
  const _MaterialDraft({
    required this.code,
    required this.name,
    this.type,
    this.gsm,
    this.sheetWidthMm,
    this.sheetHeightMm,
    required this.costPerSheetFils,
    this.supplierId,
  });

  final String code;
  final String name;
  final String? type;
  final int? gsm;
  final int? sheetWidthMm;
  final int? sheetHeightMm;
  final int costPerSheetFils;
  final String? supplierId;
}

class _MaterialDialog extends StatefulWidget {
  const _MaterialDialog({this.existing});

  final Map<String, Object?>? existing;

  @override
  State<_MaterialDialog> createState() => _MaterialDialogState();
}

class _MaterialDialogState extends State<_MaterialDialog> {
  late final TextEditingController _code = TextEditingController(
    text: widget.existing?['code'] as String? ?? '',
  );
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?['name'] as String? ?? '',
  );
  late final TextEditingController _kind = TextEditingController(
    text: widget.existing?['type'] as String? ?? '',
  );
  late final TextEditingController _gsm = TextEditingController(
    text: (widget.existing?['gsm'] as num?)?.toString() ?? '',
  );
  late final TextEditingController _width = TextEditingController(
    text: (widget.existing?['sheet_width_mm'] as num?)?.toString() ?? '',
  );
  late final TextEditingController _height = TextEditingController(
    text: (widget.existing?['sheet_height_mm'] as num?)?.toString() ?? '',
  );
  late final TextEditingController _cost = TextEditingController(
    text: widget.existing == null
        ? ''
        : Fils(
            (widget.existing!['cost_per_sheet_fils'] as num?)?.toInt() ?? 0,
          ).aedText,
  );
  late final TextEditingController _supplier = TextEditingController(
    text: widget.existing?['supplier_id'] as String? ?? '',
  );
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _code,
      _name,
      _kind,
      _gsm,
      _width,
      _height,
      _cost,
      _supplier,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_code.text.trim().length < 2) {
      setState(() => _error = 'Give the paper a short code.');
      return;
    }
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Give the paper a name the counter recognises.');
      return;
    }
    Navigator.of(context).pop(
      _MaterialDraft(
        code: _code.text.trim().toLowerCase().replaceAll(' ', '_'),
        name: _name.text.trim(),
        type: _kind.text.trim().isEmpty ? null : _kind.text.trim(),
        gsm: int.tryParse(_gsm.text.trim()),
        sheetWidthMm: int.tryParse(_width.text.trim()),
        sheetHeightMm: int.tryParse(_height.text.trim()),
        costPerSheetFils: _filsFromAed(_cost.text) ?? 0,
        supplierId: _supplier.text.trim().isEmpty
            ? null
            : _supplier.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_editing ? 'Edit paper' : 'Add paper'),
      content: SizedBox(
        width: dialogWidth(context, max: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _code,
                      autofocus: !_editing,
                      enabled: !_editing,
                      decoration: const InputDecoration(
                        labelText: 'Code',
                        hintText: 'art_card_350',
                      ),
                    ),
                  ),
                  const SizedBox(width: StarSpace.md),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Art card 350 gsm',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StarSpace.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _kind,
                      decoration: const InputDecoration(
                        labelText: 'Kind',
                        hintText: 'sheet, roll, card, vinyl',
                      ),
                    ),
                  ),
                  const SizedBox(width: StarSpace.md),
                  Expanded(
                    child: TextField(
                      controller: _gsm,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'GSM'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StarSpace.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _width,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sheet width (mm)',
                      ),
                    ),
                  ),
                  const SizedBox(width: StarSpace.md),
                  Expanded(
                    child: TextField(
                      controller: _height,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sheet height (mm)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StarSpace.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _cost,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cost per sheet',
                        prefixText: 'AED ',
                      ),
                    ),
                  ),
                  const SizedBox(width: StarSpace.md),
                  Expanded(
                    child: TextField(
                      controller: _supplier,
                      decoration: const InputDecoration(labelText: 'Supplier'),
                    ),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: StarSpace.sm),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_editing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

class _MachineDraft {
  const _MachineDraft({
    required this.name,
    required this.type,
    required this.hourlyRateFils,
    required this.setupMinutes,
    required this.sheetsPerHour,
    required this.plateCostFils,
    required this.clickFils,
  });

  final String name;
  final String type;
  final int hourlyRateFils;
  final int setupMinutes;
  final int sheetsPerHour;
  final int plateCostFils;
  final int clickFils;
}

class _MachineDialog extends StatefulWidget {
  const _MachineDialog({this.existing});

  final Machine? existing;

  @override
  State<_MachineDialog> createState() => _MachineDialogState();
}

class _MachineDialogState extends State<_MachineDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _hourly = TextEditingController(
    text: widget.existing == null
        ? ''
        : Fils(widget.existing!.hourlyRateFils).aedText,
  );
  late final TextEditingController _setup = TextEditingController(
    text: widget.existing?.setupMinutes.toString() ?? '',
  );
  late final TextEditingController _speed = TextEditingController(
    text: widget.existing?.sheetsPerHour.toString() ?? '',
  );
  late final TextEditingController _click = TextEditingController(
    text: widget.existing == null
        ? ''
        : Fils(widget.existing!.clickFils).aedText,
  );
  late final TextEditingController _plate = TextEditingController(
    text: widget.existing == null
        ? ''
        : Fils(widget.existing!.plateCostFils).aedText,
  );
  late String _type = widget.existing?.type ?? 'digital';
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _name,
      _hourly,
      _setup,
      _speed,
      _click,
      _plate,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Give the press a name.');
      return;
    }
    Navigator.of(context).pop(
      _MachineDraft(
        name: _name.text.trim(),
        type: _type,
        hourlyRateFils: _filsFromAed(_hourly.text) ?? 0,
        setupMinutes: int.tryParse(_setup.text.trim()) ?? 0,
        sheetsPerHour: int.tryParse(_speed.text.trim()) ?? 0,
        plateCostFils: _filsFromAed(_plate.text) ?? 0,
        clickFils: _filsFromAed(_click.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_editing ? 'Edit press' : 'Add a press'),
      content: SizedBox(
        width: dialogWidth(context, max: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _name,
                      autofocus: !_editing,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Xerox 3100',
                      ),
                    ),
                  ),
                  const SizedBox(width: StarSpace.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(labelText: 'Kind'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: 'offset',
                          child: Text('Offset'),
                        ),
                        DropdownMenuItem(
                          value: 'digital',
                          child: Text('Digital'),
                        ),
                        DropdownMenuItem(
                          value: 'large_format',
                          child: Text('Large format'),
                        ),
                        DropdownMenuItem(
                          value: 'finishing',
                          child: Text('Finishing'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _type = value ?? _type),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StarSpace.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _hourly,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Hourly rate',
                        prefixText: 'AED ',
                      ),
                    ),
                  ),
                  const SizedBox(width: StarSpace.md),
                  Expanded(
                    child: TextField(
                      controller: _click,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Per click',
                        prefixText: 'AED ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StarSpace.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _setup,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Setup (min)',
                      ),
                    ),
                  ),
                  const SizedBox(width: StarSpace.md),
                  Expanded(
                    child: TextField(
                      controller: _speed,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sheets per hour',
                      ),
                    ),
                  ),
                  const SizedBox(width: StarSpace.md),
                  Expanded(
                    child: TextField(
                      controller: _plate,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Plate cost',
                        prefixText: 'AED ',
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: StarSpace.sm),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_editing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

class _OperationDraft {
  const _OperationDraft({
    required this.code,
    required this.nameEn,
    required this.phase,
    required this.basis,
    required this.rateFils,
    required this.setupFils,
    required this.wasteBps,
    required this.minChargeFils,
  });

  final String code;
  final String nameEn;
  final String phase;
  final String basis;
  final int rateFils;
  final int setupFils;
  final int wasteBps;
  final int minChargeFils;
}

class _OperationDialog extends StatefulWidget {
  const _OperationDialog({this.existing});

  final Operation? existing;

  @override
  State<_OperationDialog> createState() => _OperationDialogState();
}

class _OperationDialogState extends State<_OperationDialog> {
  late final TextEditingController _code = TextEditingController(
    text: widget.existing?.code ?? '',
  );
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.nameEn ?? '',
  );
  late final TextEditingController _rate = TextEditingController(
    text: widget.existing == null
        ? ''
        : Fils(widget.existing!.rateFils).aedText,
  );
  late final TextEditingController _setup = TextEditingController(
    text: widget.existing == null
        ? ''
        : Fils(widget.existing!.setupFils).aedText,
  );
  late final TextEditingController _waste = TextEditingController(
    text: widget.existing?.wasteBps.toString() ?? '',
  );
  late final TextEditingController _min = TextEditingController(
    text: widget.existing == null
        ? ''
        : Fils(widget.existing!.minChargeFils).aedText,
  );
  late String _phase = widget.existing?.phase ?? 'finishing';
  late String _basis = widget.existing?.basis ?? 'per_piece';
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _code,
      _name,
      _rate,
      _setup,
      _waste,
      _min,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_code.text.trim().length < 2) {
      setState(() => _error = 'Give the step a short code.');
      return;
    }
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Give the step a name.');
      return;
    }
    Navigator.of(context).pop(
      _OperationDraft(
        code: _code.text.trim().toLowerCase().replaceAll(' ', '_'),
        nameEn: _name.text.trim(),
        phase: _phase,
        basis: _basis,
        rateFils: _filsFromAed(_rate.text) ?? 0,
        setupFils: _filsFromAed(_setup.text) ?? 0,
        wasteBps: int.tryParse(_waste.text.trim()) ?? 0,
        minChargeFils: _filsFromAed(_min.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_editing ? 'Edit finishing step' : 'Add a finishing step'),
      content: SizedBox(
        width: dialogWidth(context, max: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _code,
                      autofocus: !_editing,
                      enabled: !_editing,
                      decoration: const InputDecoration(
                        labelText: 'Code',
                        hintText: 'lam_matt',
                      ),
                    ),
                  ),
                  const SizedBox(width: StarSpace.md),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Matt lamination',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StarSpace.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _phase,
                      decoration: const InputDecoration(labelText: 'Phase'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: 'prepress',
                          child: Text('Prepress'),
                        ),
                        DropdownMenuItem(value: 'print', child: Text('Print')),
                        DropdownMenuItem(
                          value: 'finishing',
                          child: Text('Finishing'),
                        ),
                        DropdownMenuItem(
                          value: 'packing',
                          child: Text('Packing'),
                        ),
                        DropdownMenuItem(
                          value: 'delivery',
                          child: Text('Delivery'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _phase = value ?? _phase),
                    ),
                  ),
                  const SizedBox(width: StarSpace.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _basis,
                      decoration: const InputDecoration(labelText: 'Basis'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: 'per_piece',
                          child: Text('Per piece'),
                        ),
                        DropdownMenuItem(
                          value: 'per_1000',
                          child: Text('Per 1000'),
                        ),
                        DropdownMenuItem(
                          value: 'per_side',
                          child: Text('Per side'),
                        ),
                        DropdownMenuItem(
                          value: 'per_sqm',
                          child: Text('Per m²'),
                        ),
                        DropdownMenuItem(
                          value: 'per_copy',
                          child: Text('Per copy'),
                        ),
                        DropdownMenuItem(
                          value: 'per_hour',
                          child: Text('Per hour'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _basis = value ?? _basis),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StarSpace.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _rate,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Rate',
                        prefixText: 'AED ',
                      ),
                    ),
                  ),
                  const SizedBox(width: StarSpace.md),
                  Expanded(
                    child: TextField(
                      controller: _setup,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Setup',
                        prefixText: 'AED ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StarSpace.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _waste,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Waste',
                        suffixText: 'bps',
                      ),
                    ),
                  ),
                  const SizedBox(width: StarSpace.md),
                  Expanded(
                    child: TextField(
                      controller: _min,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Minimum charge',
                        prefixText: 'AED ',
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: StarSpace.sm),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_editing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

/// AED text ("3.50") into fils, or null when unparseable/negative.
int? _filsFromAed(String text) {
  final value = double.tryParse(text.trim());
  if (value == null || value < 0) return null;
  return (value * 100).round();
}
