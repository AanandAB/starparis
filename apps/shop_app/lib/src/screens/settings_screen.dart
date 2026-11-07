import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';

import '../app_config.dart';
import '../providers.dart';
import '../sales/settings_service.dart';
import '../tour/app_tour.dart';

/// Settings — the values printed on every document, and the rate charged on
/// every invoice.
///
/// Owner only, and saved to the server: a shop that changes its TRN must change
/// it once, not once per device. The screen says plainly what it affects.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _trn = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _vat = TextEditingController();
  final TextEditingController _orderPrefix = TextEditingController();
  final TextEditingController _invoicePrefix = TextEditingController();
  final TextEditingController _quotePrefix = TextEditingController();

  bool _busy = false;
  String? _loadedFrom;

  /// Fills the form the first time the server answers, and again after a save.
  void _fill(ShopSettings settings) {
    final stamp =
        '${settings.company.trn}|${settings.vatBps}|${settings.company.name}';
    if (_loadedFrom == stamp) return;
    _loadedFrom = stamp;
    _name.text = settings.company.name;
    _trn.text = settings.company.trn;
    _address.text = settings.company.address;
    _phone.text = settings.company.phone;
    _email.text = settings.company.email ?? '';
    _vat.text = settings.vatPercent;
    _orderPrefix.text = settings.orderPrefix;
    _invoicePrefix.text = settings.invoicePrefix;
    _quotePrefix.text = settings.quotePrefix;
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _name,
      _trn,
      _address,
      _phone,
      _email,
      _vat,
      _orderPrefix,
      _invoicePrefix,
      _quotePrefix,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final vat = double.tryParse(_vat.text.trim());
    if (vat == null || vat < 0 || vat > 100) {
      _say('VAT must be a percentage between 0 and 100.');
      return;
    }
    final trn = _trn.text.trim();
    if (trn.isNotEmpty && !RegExp(r'^\d{15}$').hasMatch(trn)) {
      _say('A UAE TRN is 15 digits.');
      return;
    }

    setState(() => _busy = true);
    final bootstrap = ref.read(bootstrapProvider);
    final service = SettingsService(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: bootstrap.auth.accessToken,
    );
    try {
      await service.save(
        name: _name.text.trim(),
        trn: trn,
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        vatBps: (vat * 100).round(),
        orderPrefix: _orderPrefix.text.trim(),
        invoicePrefix: _invoicePrefix.text.trim(),
        quotePrefix: _quotePrefix.text.trim(),
      );
      ref.invalidate(shopSettingsProvider);
      _say('Saved. New documents will use these details.');
    } catch (error) {
      _say('$error');
    } finally {
      service.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(shopSettingsProvider);

    return settings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(StarSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Settings need a connection',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: StarSpace.sm),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: StarSpace.md),
              FilledButton(
                onPressed: () => ref.invalidate(shopSettingsProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
      data: (value) {
        _fill(value);
        return ListView(
          padding: const EdgeInsets.all(StarSpace.lg),
          children: <Widget>[
            ScreenHeader(
              title: 'Settings',
              subtitle: 'What is printed on every document, and the VAT the shop charges.',
              actions: <Widget>[
                FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save'),
                ),
              ],
            ),
            StarSectionHeader(
              title: 'On every document',
              subtitle: 'Invoices, quotes and job tickets take these values the next time they are made.',
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(StarSpace.lg),
                child: Column(
                  children: <Widget>[
                    _field(_name, 'Registered name'),
                    _field(_trn, 'TRN', hint: '15 digits'),
                    _field(_address, 'Address', maxLines: 2),
                    Row(
                      children: <Widget>[
                        Expanded(child: _field(_phone, 'Phone')),
                        const SizedBox(width: StarSpace.md),
                        Expanded(child: _field(_email, 'Email')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: StarSpace.xl),
            StarSectionHeader(
              title: 'VAT',
              subtitle: 'Charged on new invoices. Issued invoices keep the rate they were made with — that is what makes them reproducible.',
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(StarSpace.lg),
                child: _field(_vat, 'Rate', suffix: '%', hint: '5.00'),
              ),
            ),
            const SizedBox(height: StarSpace.xl),
            StarSectionHeader(
              title: 'Number prefixes',
              subtitle: 'What a number starts with. Existing numbers never change; this affects the next one issued.',
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(StarSpace.lg),
                child: Row(
                  children: <Widget>[
                    Expanded(child: _field(_orderPrefix, 'Jobs')),
                    const SizedBox(width: StarSpace.md),
                    Expanded(child: _field(_invoicePrefix, 'Invoices')),
                    const SizedBox(width: StarSpace.md),
                    Expanded(child: _field(_quotePrefix, 'Quotes')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: StarSpace.xl),
            StarSectionHeader(
              title: 'Help',
              subtitle: 'Replay the guided tour that walks new staff through the app.',
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Replay the guided tour'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ref.read(appTourProvider.notifier).start(),
              ),
            ),
            const SizedBox(height: StarSpace.xl),
            Text(
              'Saved to the shop, not to this device: every counter prints the '
              'same name, TRN and rate.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: StarSpace.xxl),
          ],
        );
      },
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    String? suffix,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: StarSpace.sm),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: suffix,
        ),
      ),
    );
  }
}
