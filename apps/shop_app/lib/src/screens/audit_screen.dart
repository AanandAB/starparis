import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';

import '../providers.dart';
import '../sales/audit_service.dart';

/// Opens the audit trail as a page of its own.
///
/// A page rather than the sheet the activity log uses: reading the trail is a
/// scan down a list, and a sheet would give it three rows of height with a drag
/// handle across the top.
Future<void> openAuditLog(BuildContext context) {
  return Navigator.of(context)
      .push<void>(MaterialPageRoute<void>(builder: (_) => const AuditScreen()));
}

/// The four questions the trail is actually opened to answer.
///
/// One chip per question, not per action code: nobody goes looking for
/// `price.product.update`, they go looking for who changed a price. The codes
/// behind each chip are therefore matched here, on the device, rather than sent
/// as one `?action=` the server could not honour for three of the four.
enum _AuditFilter {
  all('All'),
  signIns('Sign-ins'),
  prices('Price changes'),
  other('Everything else');

  const _AuditFilter(this.label);

  final String label;

  bool accepts(AuditEntry entry) => switch (this) {
    _AuditFilter.all => true,
    // Everything the sign-in path writes: a success, a wrong password, and the
    // lockout that follows too many of them.
    _AuditFilter.signIns => entry.action.startsWith('auth.login'),
    _AuditFilter.prices => entry.action.startsWith('price.'),
    _AuditFilter.other =>
      !entry.action.startsWith('auth.login') &&
          !entry.action.startsWith('price.'),
  };
}

/// Who signed in and who changed a price, as the server recorded it.
///
/// This screen needs the network on purpose, like Staff. The trail is the
/// shop's, not this tablet's: the interesting rows are the ones the device
/// itself never saw, and a local copy could be edited between two people
/// reading it. It says so instead of showing an empty list that looks like
/// nothing ever happened.
class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  _AuditFilter _filter = _AuditFilter.all;

  void _reload() => ref.invalidate(auditEntriesProvider);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audit = ref.watch(auditEntriesProvider);
    final entries = audit.value ?? const <AuditEntry>[];
    // Filtering is instant and local because the page is already in memory; a
    // round trip per chip would make a log feel slower than the paper it saves.
    final shown = entries.where(_filter.accepts).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        // The header below carries the title. The bar is here for the way back
        // on a phone, where there is no rail to click.
        toolbarHeight: 48,
      ),
      body: ListView(
        padding: const EdgeInsets.all(StarSpace.lg),
        children: <Widget>[
          ScreenHeader(
            title: 'Audit log',
            subtitle:
                'Who signed in and who changed a price. Read from the '
                'server — this page needs a connection.',
            actions: <Widget>[
              TextButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          Wrap(
            spacing: StarSpace.sm,
            runSpacing: StarSpace.sm,
            children: <Widget>[
              for (final filter in _AuditFilter.values)
                FilterChip(
                  label: Text(filter.label),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
            ],
          ),
          const SizedBox(height: StarSpace.lg),
          if (audit.isLoading)
            const StarSkeletonList(rows: 6, rowHeight: 56)
          else if (audit.hasError)
            _ErrorCard(message: '${audit.error}', onRetry: _reload)
          else if (shown.isEmpty)
            EmptyState(
              icon: Icons.history_toggle_off,
              title: _emptyTitle,
              message: _emptyMessage,
              actionLabel: 'Look again',
              onAction: _reload,
            )
          else
            _TrailCard(entries: shown),
          const SizedBox(height: StarSpace.lg),
          // Only once there is something to describe: "the newest 0 entries"
          // while the page is still loading reads like an empty trail.
          if (audit.hasValue)
            Text(
              'The newest ${entries.length} entries the server returned, newest '
              'first. Older history stays on the server, and none of this is '
              'stored on the device.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: StarSpace.xl),
        ],
      ),
    );
  }

  /// What an empty list means depends on the chip: "no price changes" is a
  /// reassuring answer, "nothing at all" is a suspicion. One shared sentence
  /// would make the two indistinguishable.
  String get _emptyTitle => switch (_filter) {
    _AuditFilter.all => 'The trail is empty',
    _AuditFilter.signIns => 'Nobody signed in',
    _AuditFilter.prices => 'No price changes',
    _AuditFilter.other => 'Nothing else happened',
  };

  String get _emptyMessage => switch (_filter) {
    _AuditFilter.all =>
      'Sign-ins and price changes land here as they happen. An empty trail on '
          'a shop that has been open is worth a question.',
    _AuditFilter.signIns =>
      'No successful, failed or blocked sign-in in the entries loaded.',
    _AuditFilter.prices =>
      'No price rule, product or price break was edited in the entries loaded.',
    _AuditFilter.other =>
      'Nothing outside sign-ins and price edits in the entries loaded.',
  };
}

/// The trail itself: one card, so the rows read as one continuous story.
class _TrailCard extends StatelessWidget {
  const _TrailCard({required this.entries});

  final List<AuditEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          for (var i = 0; i < entries.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1),
            _AuditRow(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plain = _plainAction(entry.action);

    return ListTile(
      // A 3px bar, not a coloured row: the eye finds the alarming entries while
      // scanning, and every word stays the theme's own colour so the list is
      // readable in the light and the dark interface alike.
      leading: Container(
        width: 3,
        height: 36,
        decoration: BoxDecoration(
          color: _accent(context, entry.action),
          borderRadius: BorderRadius.circular(StarRadius.chip),
        ),
      ),
      title: Text(
        plain ?? entry.action,
        // An action with no plain wording shows its code, in monospace, so it
        // is obvious that the app is quoting the server rather than describing
        // it — and so a new action code never gets a guess at a label.
        style: plain == null
            ? theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')
            : theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        entry.actorLabel,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        _stamp(entry.at),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// The failure state, with the one thing worth doing about it.
///
/// It names the connection because that is nearly always the cause, and it says
/// the rest of the app still works so nobody concludes the till is down.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
                  'Audit log needs a connection',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: StarSpace.sm),
            Text(message, style: theme.textTheme.bodySmall),
            const SizedBox(height: StarSpace.sm),
            Text(
              'The trail lives on the server. Everything else on this device '
              'still works offline.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: StarSpace.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sentence a shopkeeper would use for an action, or null when the app has
/// no honest one.
///
/// Deliberately short, and deliberately incomplete: `auth.logout` and the rest
/// fall through to the raw code. A made-up phrase for an event nobody has had
/// to read yet is worse than the code, because it hides what actually happened.
String? _plainAction(String action) => switch (action) {
  'auth.login' => 'Signed in',
  'auth.login_failed' => 'Wrong password',
  'auth.login_throttled' => 'Locked out',
  _ when action.startsWith('price.') => 'Changed a price',
  _ => null,
};

/// Which rows are alarming, as a colour — never as the only signal.
Color _accent(BuildContext context, String action) => switch (action) {
  'auth.login' => StarColors.statusDone,
  'auth.login_failed' => StarColors.statusProblem,
  'auth.login_throttled' => StarColors.statusPaused,
  _ when action.startsWith('price.') => StarColors.ember,
  _ => Theme.of(context).colorScheme.outlineVariant,
};

const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// `HH:mm dd MMM`. The date stays on every row, today's included: a trail is
/// read days later far more often than in the minute it was written.
String _stamp(DateTime at) {
  final hour = at.hour.toString().padLeft(2, '0');
  final minute = at.minute.toString().padLeft(2, '0');
  final day = at.day.toString().padLeft(2, '0');
  return '$hour:$minute $day ${_months[at.month - 1]}';
}
