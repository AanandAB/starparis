import 'package:flutter/widgets.dart';

/// Width for a modal form dialog that always fits the screen.
///
/// Desktop forms want a comfortable fixed width, but that same fixed width
/// overflows a phone and clips the fields (and squeezes text into vertical
/// letters). This caps at [max] and shrinks to the screen minus a small
/// inset, so the form never runs off the edge.
double dialogWidth(BuildContext context, {double max = 560}) {
  final available = MediaQuery.sizeOf(context).width - 48;
  return available < max ? available : max;
}
