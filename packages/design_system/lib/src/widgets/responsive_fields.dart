import 'package:flutter/widgets.dart';

import '../tokens.dart';

/// A form row that stacks its fields vertically on narrow screens.
///
/// Forms laid out as `Row(Expanded(field), Expanded(field))` look tidy on
/// desktop but squeeze two text fields into a phone's width, leaving labels
/// and hints to wrap into vertical letters. This keeps the side-by-side
/// layout only when there is room and stacks one field per line (full width)
/// below the compact breakpoint.
class ResponsiveFields extends StatelessWidget {
  const ResponsiveFields({
    super.key,
    required this.children,
    this.weights,
    this.gap = StarSpace.md,
  });

  /// One widget per field, in reading order.
  final List<Widget> children;

  /// Desktop flex weights, matching [children]. Defaults to all-equal. Some
  /// forms pass `[1, 2]` so a short code sits beside a wider name. Ignored on
  /// narrow screens, where every field is full width.
  final List<int>? weights;

  /// Gap between fields — horizontal on wide, vertical on narrow.
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < StarBreakpoints.compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      );
    }
    final flex = weights ?? List<int>.filled(children.length, 1);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (var i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) SizedBox(width: gap),
          Expanded(flex: flex[i], child: children[i]),
        ],
      ],
    );
  }
}
