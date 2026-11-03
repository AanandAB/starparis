import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';

import '../providers.dart';
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
            StarSpace.md,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  onChanged: (value) =>
                      ref.read(searchQueryProvider.notifier).set(value),
                  decoration: const InputDecoration(
                    hintText: 'Search by phone, name or company',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: StarSpace.md),
              FilledButton.icon(
                onPressed: () => showNewCustomerSheet(context),
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: const Text('New customer'),
              ),
            ],
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
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return ListTile(
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
