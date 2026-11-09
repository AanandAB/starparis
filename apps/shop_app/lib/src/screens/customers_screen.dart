import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../providers.dart';
import '../sales/customer_sheet.dart';
import '../sales/excel_export_service.dart';
import 'new_customer_sheet.dart';

/// The directory the counter actually uses: search by phone number first,
/// because that is what the customer gives you.
class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final results = ref.watch(customerResultsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StarSpace.lg,
            StarSpace.lg,
            StarSpace.lg,
            0,
          ),
          child: const ScreenHeader(
            title: 'Customers',
            subtitle:
                'Find by phone number: the counter types digits, not names.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StarSpace.lg,
            StarSpace.lg,
            StarSpace.lg,
            StarSpace.md,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final search = TextField(
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).set(value),
                decoration: const InputDecoration(
                  hintText: 'Search by phone, name or company',
                  prefixIcon: Icon(Icons.search),
                ),
              );
              final newButton = FilledButton.icon(
                onPressed: () => showNewCustomerSheet(context),
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: const Text('New customer'),
              );
              final exportButton = OutlinedButton.icon(
                onPressed: () => _exportCustomers(context, ref),
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Export'),
              );
              if (constraints.maxWidth < StarBreakpoints.compact) {
                // The buttons drop below the search field, so a phone never
                // squeezes the field (and its search icon) out of sight.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    search,
                    const SizedBox(height: StarSpace.sm),
                    Wrap(
                      spacing: StarSpace.sm,
                      runSpacing: StarSpace.sm,
                      children: <Widget>[newButton, exportButton],
                    ),
                  ],
                );
              }
              return Row(
                children: <Widget>[
                  Expanded(child: search),
                  const SizedBox(width: StarSpace.md),
                  newButton,
                  const SizedBox(width: StarSpace.md),
                  exportButton,
                ],
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: results.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Could not read the local database',
              message: '$error',
            ),
            data: (customers) {
              if (customers.isEmpty) {
                return EmptyState(
                  icon: Icons.people_outline,
                  title: 'No customers yet',
                  message: 'Add the first one — name and phone number is enough, and it works offline.',
                  actionLabel: 'Add a customer',
                  onAction: () => showNewCustomerSheet(context),
                );
              }
              return ListView.separated(
                itemCount: customers.length,
                separatorBuilder: (_, index) =>
                    const SizedBox(height: StarSpace.sm),
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  // PressableCard makes the whole row lift on hover and ripple
                  // on tap, so a row reads as a door, not a line of text.
                  return PressableCard(
                    onTap: () => showCustomerSheet(context, customer),
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.10,
                        ),
                        child: Text(
                          customer.name.characters.first.toUpperCase(),
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ),
                      title: Text(customer.name),
                      subtitle: Text(
                        <String>[
                          if (customer.company != null &&
                              customer.company!.isNotEmpty)
                            customer.company!,
                          customer.tier,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: customer.version == 0
                          ? const StatusChip(
                              label: 'Pending upload',
                              tone: StatusTone.paused,
                              icon: Icons.cloud_upload_outlined,
                            )
                          : const Icon(Icons.chevron_right),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Writes the customers currently on screen to an .xlsx in the shop's
/// documents folder and tells the counter where it went. Offline only: the
/// rows come from the local database and nothing is fetched.
Future<void> _exportCustomers(BuildContext context, WidgetRef ref) async {
  // Capture the messenger before the first await so the snackbar is shown
  // through a messenger that is still mounted.
  final messenger = ScaffoldMessenger.of(context);
  try {
    final db = ref.read(bootstrapProvider).db;
    final customers =
        ref.read(customerResultsProvider).value ?? const <Customer>[];
    final file = await exportCustomersToXlsx(db, customers);
    messenger.showSnackBar(
      SnackBar(content: Text('Customers saved: ${file.path}')),
    );
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text('$error')));
  }
}
