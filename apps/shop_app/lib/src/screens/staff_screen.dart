import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';

import '../app_config.dart';
import '../providers.dart';
import '../sales/staff_service.dart';

/// Staff — who can sign in, and what they are allowed to do.
///
/// This screen needs the network on purpose. Rights are a shop-wide fact: a
/// tablet that has been offline for a week must not be able to hand out an owner
/// role. Everything else in the app keeps working offline; this one says what it
/// needs rather than pretending.
class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  late Future<List<StaffMember>> _staff = _load();

  Future<List<StaffMember>> _load() {
    final bootstrap = ref.read(bootstrapProvider);
    final service = StaffService(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: bootstrap.auth.accessToken,
    );
    return service.list().whenComplete(service.dispose);
  }

  void _refresh() => setState(() => _staff = _load());

  Future<void> _add() async {
    final draft = await showDialog<_NewStaff>(
      context: context,
      builder: (_) => const _NewStaffDialog(),
    );
    if (draft == null || !mounted) return;

    final bootstrap = ref.read(bootstrapProvider);
    final service = StaffService(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: bootstrap.auth.accessToken,
    );
    final messenger = ScaffoldMessenger.of(context);
    try {
      await service.create(
        name: draft.name,
        phone: draft.phone,
        role: draft.role,
        password: draft.password,
        pin: draft.pin,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('${draft.name} can sign in now.')),
      );
      _refresh();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      service.dispose();
    }
  }

  Future<void> _edit(StaffMember member) async {
    final change = await showDialog<_StaffChange>(
      context: context,
      builder: (_) => _EditStaffDialog(member: member),
    );
    if (change == null || !mounted) return;

    final bootstrap = ref.read(bootstrapProvider);
    final service = StaffService(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: bootstrap.auth.accessToken,
    );
    final messenger = ScaffoldMessenger.of(context);
    try {
      await service.update(
        member.id,
        role: change.role,
        active: change.active,
        password: change.password,
        pin: change.pin,
      );
      messenger.showSnackBar(const SnackBar(content: Text('Saved.')));
      _refresh();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      service.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<StaffMember>>(
      future: _staff,
      builder: (context, snapshot) {
        return ListView(
          padding: const EdgeInsets.all(StarSpace.lg),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Staff', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 2),
                      Text(
                        'Who can sign in, and what each of them may do.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
                const SizedBox(width: StarSpace.sm),
                FilledButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Add staff'),
                ),
              ],
            ),
            const SizedBox(height: StarSpace.lg),
            if (snapshot.connectionState == ConnectionState.waiting)
              const StarSkeletonList(rows: 4, rowHeight: 64)
            else if (snapshot.hasError)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(StarSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Staff list needs a connection',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: StarSpace.xs),
                      Text(
                        '${snapshot.error}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Column(
                  children: <Widget>[
                    for (var i = 0; i < snapshot.data!.length; i++) ...<Widget>[
                      if (i > 0) const Divider(height: 1),
                      _StaffRow(
                        member: snapshot.data![i],
                        onTap: () => _edit(snapshot.data![i]),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: StarSpace.xl),
            Text(
              'A person signs in with their phone number and password. The PIN '
              'unlocks a device that is already signed in — useful at the counter, '
              'where the same tablet is used by several people in a day.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({required this.member, required this.onTap});

  final StaffMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = member.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: member.active
            ? StarColors.petrol
            : theme.colorScheme.surfaceContainerHighest,
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: member.active
                ? Colors.white
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      title: Text(member.name, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        <String>[
          member.roleLabel,
          member.phone,
          if (member.branchName != null) member.branchName!,
        ].join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (member.hasPin)
            Padding(
              padding: const EdgeInsets.only(right: StarSpace.sm),
              child: Tooltip(
                message: 'Can unlock with a PIN',
                child: Icon(
                  Icons.pin_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          StatusChip(
            label: member.active ? 'Active' : 'Off',
            tone: member.active ? StatusTone.done : StatusTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _NewStaff {
  const _NewStaff({
    required this.name,
    required this.phone,
    required this.role,
    required this.password,
    this.pin,
  });

  final String name;
  final String phone;
  final String role;
  final String password;
  final String? pin;
}

class _NewStaffDialog extends StatefulWidget {
  const _NewStaffDialog();

  @override
  State<_NewStaffDialog> createState() => _NewStaffDialogState();
}

class _NewStaffDialogState extends State<_NewStaffDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _pin = TextEditingController();
  String _role = 'designer';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Give the person a name.');
      return;
    }
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) {
      setState(() => _error = 'A phone number is what they sign in with.');
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = 'A password needs at least eight characters.');
      return;
    }
    final pin = _pin.text.trim();
    if (pin.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _error = 'A PIN is four digits.');
      return;
    }

    Navigator.of(context).pop(
      _NewStaff(
        name: _name.text.trim(),
        phone: '+$digits',
        role: _role,
        password: _password.text,
        pin: pin.isEmpty ? null : pin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a person'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
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
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (this is their login)',
                  prefixText: '+',
                ),
              ),
              const SizedBox(height: StarSpace.sm),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(
                    value: 'counter',
                    child: Text('Sales / Counter'),
                  ),
                  DropdownMenuItem(value: 'designer', child: Text('Designer')),
                  DropdownMenuItem(value: 'operator', child: Text('Operator')),
                  DropdownMenuItem(
                    value: 'accountant',
                    child: Text('Accountant'),
                  ),
                  DropdownMenuItem(
                    value: 'vendor_coordinator',
                    child: Text('Vendor coordinator'),
                  ),
                  DropdownMenuItem(value: 'driver', child: Text('Driver')),
                ],
                onChanged: (value) => setState(() => _role = value ?? _role),
              ),
              const SizedBox(height: StarSpace.sm),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'First password',
                  helperText:
                      'Give it to them; they can change it by asking you.',
                ),
              ),
              const SizedBox(height: StarSpace.sm),
              TextField(
                controller: _pin,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Counter PIN (optional)',
                  helperText: 'Four digits, for a device already signed in.',
                  counterText: '',
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: StarSpace.sm),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
        FilledButton(onPressed: _save, child: const Text('Create')),
      ],
    );
  }
}

class _StaffChange {
  const _StaffChange({this.role, this.active, this.password, this.pin});

  final String? role;
  final bool? active;
  final String? password;
  final String? pin;
}

class _EditStaffDialog extends StatefulWidget {
  const _EditStaffDialog({required this.member});

  final StaffMember member;

  @override
  State<_EditStaffDialog> createState() => _EditStaffDialogState();
}

class _EditStaffDialogState extends State<_EditStaffDialog> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _pin = TextEditingController();
  late String _role = widget.member.role;
  late bool _active = widget.member.active;

  @override
  void dispose() {
    _password.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _save() {
    final password = _password.text.trim();
    if (password.isNotEmpty && password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A password needs at least eight characters.'),
        ),
      );
      return;
    }
    final pin = _pin.text.trim();
    if (pin.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(pin)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('A PIN is four digits.')));
      return;
    }

    Navigator.of(context).pop(
      _StaffChange(
        role: _role == widget.member.role ? null : _role,
        active: _active == widget.member.active ? null : _active,
        password: password.isEmpty ? null : password,
        pin: pin.isEmpty ? null : pin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.member.name),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.member.phone,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: StarSpace.md),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'owner', child: Text('Owner')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(
                    value: 'counter',
                    child: Text('Sales / Counter'),
                  ),
                  DropdownMenuItem(value: 'designer', child: Text('Designer')),
                  DropdownMenuItem(value: 'operator', child: Text('Operator')),
                  DropdownMenuItem(
                    value: 'accountant',
                    child: Text('Accountant'),
                  ),
                  DropdownMenuItem(
                    value: 'vendor_coordinator',
                    child: Text('Vendor coordinator'),
                  ),
                  DropdownMenuItem(value: 'driver', child: Text('Driver')),
                ],
                onChanged: (value) => setState(() => _role = value ?? _role),
              ),
              const SizedBox(height: StarSpace.sm),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Can sign in'),
                subtitle: Text(
                  _active
                      ? 'Switching this off blocks the account immediately.'
                      : 'This account cannot sign in.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _active,
                onChanged: (value) => setState(() => _active = value),
              ),
              const SizedBox(height: StarSpace.sm),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password (optional)',
                  helperText: 'Leave empty to keep the current one.',
                ),
              ),
              const SizedBox(height: StarSpace.sm),
              TextField(
                controller: _pin,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: widget.member.hasPin
                      ? 'New PIN (optional)'
                      : 'Set a counter PIN (optional)',
                  counterText: '',
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
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
