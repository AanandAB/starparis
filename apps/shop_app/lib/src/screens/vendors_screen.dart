import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../providers.dart';
import '../tour/section_tour.dart';

/// Vendors — the work the shop does not do itself.
///
/// Two lists, because they answer two different questions: *what is out with
/// somebody else right now* (and when was it promised back), and *who do we use*.
class VendorsScreen extends ConsumerWidget {
  const VendorsScreen({super.key});

  /// The first-visit guide for the Vendors screen.
  static const List<TourStep> tourSteps = <TourStep>[
    TourStep(
      icon: Icons.storefront_outlined,
      title: 'Vendors',
      body: 'Outside shops you hand work to, and what they charge.',
    ),
    TourStep(
      anchor: 'header',
      icon: Icons.handshake_outlined,
      title: 'Hand work out',
      body: 'Add a vendor, then hand a job to them.',
    ),
    TourStep(
      anchor: 'new',
      icon: Icons.add,
      title: 'Add vendor',
      body: 'Tap Add to save a vendor.',
    ),
  ];

  /// Resolves an anchor name to the element it spotlights.
  static GlobalKey? tourAnchorFor(String? name) => switch (name) {
        'header' => const GlobalObjectKey('vendors-header'),
        'new' => const GlobalObjectKey('vendors-new'),
        _ => null,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final db = ref.watch(bootstrapProvider).db;

    return StreamBuilder<List<Vendor>>(
      stream: db.watchVendors(),
      builder: (context, vendorSnapshot) {
        final vendors = vendorSnapshot.data ?? const <Vendor>[];
        final byId = <String, Vendor>{
          for (final vendor in vendors) vendor.id: vendor,
        };

        return StreamBuilder<List<VendorJob>>(
          stream: db.watchOpenVendorJobs(),
          builder: (context, jobSnapshot) {
            final jobs = jobSnapshot.data ?? const <VendorJob>[];

            return ListView(
              padding: const EdgeInsets.all(StarSpace.lg),
              children: <Widget>[
                ScreenHeader(
                  key: const GlobalObjectKey('vendors-header'),
                  title: 'Vendors',
                  subtitle: 'Work handed to other shops, what it costs, and when it is due back.',
                  actions: <Widget>[
                    OutlinedButton.icon(
                      onPressed: () => _addVendor(context, ref),
                      icon: const Icon(Icons.store_outlined, size: 18),
                      label: const Text('Add vendor'),
                    ),
                    FilledButton.icon(
                      key: const GlobalObjectKey('vendors-new'),
                      onPressed: vendors.isEmpty
                          ? null
                          : () => _handOutWork(context, ref, vendors),
                      icon: const Icon(Icons.outbox_outlined, size: 18),
                      label: const Text('Hand out work'),
                    ),
                  ],
                ),
                const SizedBox(height: StarSpace.xl),
                StarSectionHeader(
                  title: 'Out with vendors',
                  subtitle: jobs.isEmpty
                      ? 'Nothing is with anybody else right now.'
                      : 'Send it, get it back, cost it. A job left open is money you cannot see.',
                  count: jobs.length,
                ),
                if (jobs.isEmpty)
                  const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No vendor work open',
                    message: 'When part of an order is done outside, hand it out from here so the cost and the promised date are on the job.',
                  )
                else
                  Card(
                    child: Column(
                      children: <Widget>[
                        for (var i = 0; i < jobs.length; i++) ...<Widget>[
                          if (i > 0) const Divider(height: 1),
                          _VendorJobRow(
                            job: jobs[i],
                            vendor: byId[jobs[i].vendorId],
                            onAdvance: (to) =>
                                _advance(context, ref, jobs[i], to),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: StarSpace.xl),
                StarSectionHeader(title: 'Vendors', count: vendors.length),
                if (vendors.isEmpty)
                  const EmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'No vendors yet',
                    message: 'Add the embroiderer, the binder, whoever you actually use. Then work can be handed out.',
                  )
                else
                  Card(
                    child: Column(
                      children: <Widget>[
                        for (var i = 0; i < vendors.length; i++) ...<Widget>[
                          if (i > 0) const Divider(height: 1),
                          ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.storefront_outlined,
                              size: 20,
                            ),
                            title: Text(vendors[i].name),
                            subtitle: Text(
                              <String>[
                                if (vendors[i].trade != null &&
                                    vendors[i].trade!.isNotEmpty)
                                  vendors[i].trade!,
                                if (vendors[i].phoneE164 != null)
                                  vendors[i].phoneE164!,
                              ].join(' · '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: StatusChip(
                              label: vendors[i].active ? 'Active' : 'Off',
                              tone: vendors[i].active
                                  ? StatusTone.done
                                  : StatusTone.neutral,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _advance(
    BuildContext context,
    WidgetRef ref,
    VendorJob job,
    String to,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(bootstrapProvider)
          .db
          .transitionVendorJob(job: job, to: to);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _addVendor(BuildContext context, WidgetRef ref) async {
    final draft = await showDialog<_VendorDraft>(
      context: context,
      builder: (_) => const _NewVendorDialog(),
    );
    if (draft == null || !context.mounted) return;

    final bootstrap = ref.read(bootstrapProvider);
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await bootstrap.db.createVendorLocal(
        tenantId: session.tenantId,
        branchId: session.branchId,
        userId: session.userId,
        name: draft.name,
        trade: draft.trade,
        phone: draft.phone,
      );
      messenger.showSnackBar(SnackBar(content: Text('${draft.name} saved.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _handOutWork(
    BuildContext context,
    WidgetRef ref,
    List<Vendor> vendors,
  ) async {
    final db = ref.read(bootstrapProvider).db;
    final orders = await db.watchOrders(limit: 50).first;
    if (!context.mounted) return;

    final draft = await showDialog<_JobDraft>(
      context: context,
      builder: (_) => _NewVendorJobDialog(vendors: vendors, orders: orders),
    );
    if (draft == null || !context.mounted) return;

    final bootstrap = ref.read(bootstrapProvider);
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await bootstrap.db.createVendorJobLocal(
        tenantId: session.tenantId,
        branchId: session.branchId,
        userId: session.userId,
        orderId: draft.orderId,
        vendorId: draft.vendorId,
        description: draft.description,
        costFils: draft.costFils,
        promisedAt: draft.promisedAt,
      );
      messenger.showSnackBar(const SnackBar(content: Text('Work handed out.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _VendorJobRow extends StatelessWidget {
  const _VendorJobRow({
    required this.job,
    required this.vendor,
    required this.onAdvance,
  });

  final VendorJob job;
  final Vendor? vendor;
  final void Function(String to) onAdvance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promisedLate =
        job.promisedAt != null &&
        job.promisedAt!.isBefore(DateTime.now()) &&
        job.status != 'received' &&
        job.status != 'closed';

    final next = switch (job.status) {
      'draft' => ('sent', 'Send'),
      'sent' => ('received', 'Back'),
      'received' => ('closed', 'Close'),
      _ => (null, null),
    };

    return ListTile(
      dense: true,
      title: Text(
        job.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        <String>[
          vendor?.name ?? 'Vendor',
          Fils(job.costFils).aedLabel,
          if (job.promisedAt != null)
            'back ${job.promisedAt!.day}/${job.promisedAt!.month}',
        ].join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: promisedLate
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: promisedLate ? FontWeight.w600 : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          StatusChip(label: _label(job.status), tone: _tone(job.status)),
          if (next.$1 != null) ...<Widget>[
            const SizedBox(width: StarSpace.sm),
            TextButton(
              onPressed: () => onAdvance(next.$1!),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: StarSpace.sm),
              ),
              child: Text(next.$2!),
            ),
          ],
        ],
      ),
    );
  }

  static String _label(String status) => switch (status) {
    'draft' => 'Draft',
    'sent' => 'With vendor',
    'received' => 'Back',
    'closed' => 'Closed',
    'cancelled' => 'Cancelled',
    _ => status,
  };

  static StatusTone _tone(String status) => switch (status) {
    'sent' => StatusTone.active,
    'received' => StatusTone.paused,
    'closed' => StatusTone.done,
    'cancelled' => StatusTone.problem,
    _ => StatusTone.neutral,
  };
}

class _VendorDraft {
  const _VendorDraft({required this.name, this.trade, this.phone});

  final String name;
  final String? trade;
  final String? phone;
}

class _NewVendorDialog extends StatefulWidget {
  const _NewVendorDialog();

  @override
  State<_NewVendorDialog> createState() => _NewVendorDialogState();
}

class _NewVendorDialogState extends State<_NewVendorDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _trade = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _trade.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Give the vendor a name.');
      return;
    }
    Navigator.of(context).pop(
      _VendorDraft(
        name: _name.text.trim(),
        trade: _trade.text.trim().isEmpty ? null : _trade.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a vendor'),
      content: SizedBox(
        width: dialogWidth(context, max: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: StarSpace.sm),
            TextField(
              controller: _trade,
              decoration: const InputDecoration(
                labelText: 'What they do (optional)',
                hintText: 'embroidery, binding, offset',
              ),
            ),
            const SizedBox(height: StarSpace.sm),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: StarSpace.sm),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
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

class _JobDraft {
  const _JobDraft({
    required this.orderId,
    required this.vendorId,
    required this.description,
    required this.costFils,
    this.promisedAt,
  });

  final String orderId;
  final String vendorId;
  final String description;
  final int costFils;
  final DateTime? promisedAt;
}

class _NewVendorJobDialog extends StatefulWidget {
  const _NewVendorJobDialog({required this.vendors, required this.orders});

  final List<Vendor> vendors;
  final List<Order> orders;

  @override
  State<_NewVendorJobDialog> createState() => _NewVendorJobDialogState();
}

class _NewVendorJobDialogState extends State<_NewVendorJobDialog> {
  final TextEditingController _description = TextEditingController();
  final TextEditingController _cost = TextEditingController();
  late String _vendorId = widget.vendors.first.id;
  String? _orderId;
  DateTime? _promised;
  String? _error;

  @override
  void initState() {
    super.initState();
    _orderId = widget.orders.isEmpty ? null : widget.orders.first.id;
  }

  @override
  void dispose() {
    _description.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _promised = picked);
  }

  void _save() {
    if (_orderId == null) {
      setState(() => _error = 'Choose the job this belongs to.');
      return;
    }
    if (_description.text.trim().isEmpty) {
      setState(() => _error = 'Say what the vendor is doing.');
      return;
    }
    final cost = double.tryParse(_cost.text.trim());
    if (cost == null || cost < 0) {
      setState(() => _error = 'Enter what the vendor charges.');
      return;
    }
    Navigator.of(context).pop(
      _JobDraft(
        orderId: _orderId!,
        vendorId: _vendorId,
        description: _description.text.trim(),
        costFils: (cost * 100).round(),
        promisedAt: _promised,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Hand work to a vendor'),
      content: SizedBox(
        width: dialogWidth(context, max: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: _vendorId,
                decoration: const InputDecoration(labelText: 'Vendor'),
                items: <DropdownMenuItem<String>>[
                  for (final vendor in widget.vendors)
                    DropdownMenuItem(
                      value: vendor.id,
                      child: Text(vendor.name),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _vendorId = value ?? _vendorId),
              ),
              const SizedBox(height: StarSpace.sm),
              DropdownButtonFormField<String>(
                initialValue: _orderId,
                decoration: const InputDecoration(labelText: 'Job'),
                items: <DropdownMenuItem<String>>[
                  for (final order in widget.orders)
                    DropdownMenuItem(
                      value: order.id,
                      child: Text(
                        '${order.numberDisplay} · ${order.customerName ?? ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _orderId = value),
              ),
              const SizedBox(height: StarSpace.sm),
              TextField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'What they are doing',
                  hintText: 'Embroidered logos, 50 shirts',
                ),
              ),
              const SizedBox(height: StarSpace.sm),
              TextField(
                controller: _cost,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'What they charge us',
                  prefixText: 'AED ',
                  helperText: 'The job margin is the order total less this.',
                ),
              ),
              const SizedBox(height: StarSpace.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _promised == null
                          ? 'No promised date'
                          : 'Promised back ${_promised!.day}/${_promised!.month}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: const Text('Promised date'),
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
        FilledButton(onPressed: _save, child: const Text('Hand out')),
      ],
    );
  }
}
