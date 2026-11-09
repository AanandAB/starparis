import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../providers.dart';
import 'spotlight_tour.dart';

export 'spotlight_tour.dart';

/// When set to a section id (e.g. 'orders'), forces that section's guide to
/// show regardless of whether it has been seen. Cleared on finish. This is how
/// "replay this screen's guide" and a screen's help button restart a tour.
final StateProvider<String?> sectionTourRequestProvider =
    StateProvider<String?>((ref) => null);

/// The meta key holding a section's "seen" flag.
String sectionTourKey(String id) => 'tour_seen_$id';

/// Wraps a screen's body and shows a coach-mark guide the first time that
/// section is opened (or on request). Each section has its own "seen" flag, so
/// the Orders guide runs independently of the Customers guide.
///
/// The shell keeps [activeSectionProvider] pointed at the current tab, which
/// is what lets this host run on first *visit* even though the shell builds
/// every tab up front in an IndexedStack.
class SectionTourHost extends ConsumerStatefulWidget {
  const SectionTourHost({
    super.key,
    required this.id,
    required this.steps,
    required this.anchorFor,
    required this.child,
  });

  /// Stable section id, e.g. 'orders', 'customers', 'production'.
  final String id;

  final List<TourStep> steps;

  /// Resolves a step's anchor name to the GlobalKey of the element to
  /// spotlight, within this screen's own subtree.
  final GlobalKey? Function(String? anchor) anchorFor;

  final Widget child;

  @override
  ConsumerState<SectionTourHost> createState() => _SectionTourHostState();
}

class _SectionTourHostState extends ConsumerState<SectionTourHost> {
  bool _seen = false;
  bool _checked = false;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  Future<void> _restore() async {
    var seen = true;
    try {
      seen = (await ref
              .read(bootstrapProvider)
              .db
              .meta(sectionTourKey(widget.id))) ==
          '1';
    } catch (_) {
      // No database yet: treat as seen so a fresh install is not blocked by a
      // read that cannot have been written.
      seen = true;
    }
    if (mounted) {
      setState(() {
        _seen = seen;
        _checked = true;
      });
    }
  }

  Future<void> _finish() async {
    setState(() {
      _seen = true;
      _index = 0;
    });
    try {
      await ref
          .read(bootstrapProvider)
          .db
          .setMeta(sectionTourKey(widget.id), '1');
    } catch (_) {}
    if (ref.read(sectionTourRequestProvider) == widget.id) {
      ref.read(sectionTourRequestProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeSectionProvider) == widget.id;
    final requested = ref.watch(sectionTourRequestProvider) == widget.id;
    // Show on request (replay) or on first visit to an unseen section.
    final show = requested || (active && _checked && !_seen);

    return Stack(
      children: <Widget>[
        widget.child,
        if (show)
          Positioned.fill(
            child: SpotlightOverlay(
              steps: widget.steps,
              index: _index,
              anchorFor: widget.anchorFor,
              onNext: () {
                if (_index >= widget.steps.length - 1) {
                  _finish();
                } else {
                  setState(() => _index++);
                }
              },
              onBack: () {
                if (_index > 0) setState(() => _index--);
              },
              onDone: _finish,
            ),
          ),
      ],
    );
  }
}
