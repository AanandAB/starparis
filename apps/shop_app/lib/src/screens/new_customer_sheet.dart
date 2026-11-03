import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';

import '../providers.dart';

Future<void> showNewCustomerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _NewCustomerSheet(),
  );
}

class _NewCustomerSheet extends ConsumerStatefulWidget {
  const _NewCustomerSheet();

  @override
  ConsumerState<_NewCustomerSheet> createState() => _NewCustomerSheetState();
}

class _NewCustomerSheetState extends ConsumerState<_NewCustomerSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _company = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'A name is required.');
      return;
    }
    final session = ref.read(sessionProvider);
    if (session == null) {
      setState(() => _error = 'Your session expired. Sign in again.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final bootstrap = ref.read(bootstrapProvider);
      await bootstrap.db.createCustomerLocal(
        tenantId: session.tenantId,
        branchId: session.branchId,
        name: name,
        company: _company.text.trim().isEmpty ? null : _company.text.trim(),
        phoneE164: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        userId: session.userId,
      );

      // Fire and forget: the sync loop will retry on its own, and the clerk
      // must not wait for the internet to close this sheet.
      await bootstrap.engine?.syncNow();

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer saved. It uploads automatically.'),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        StarSpace.lg,
        StarSpace.sm,
        StarSpace.lg,
        StarSpace.lg + insets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('New customer', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: StarSpace.lg),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              helperText: 'Find them next time by typing the last digits.',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: StarSpace.md),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: StarSpace.md),
          TextField(
            controller: _company,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Company (optional)',
              prefixIcon: Icon(Icons.business_outlined),
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: StarSpace.md),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: StarColors.statusProblem),
            ),
          ],
          const SizedBox(height: StarSpace.lg),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save customer'),
          ),
        ],
      ),
    );
  }
}
