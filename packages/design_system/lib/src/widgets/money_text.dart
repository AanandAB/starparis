import 'package:flutter/material.dart';
import 'package:starparis_domain/starparis_domain.dart';

/// Money, rendered the same way everywhere.
///
/// Kept in its own file so importing a money label never drags in the status
/// chips (and their icon font) on a list that shows thousands of rows.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    this.style,
    this.showCurrency = true,
    this.emphasise = false,
    super.key,
  });

  final Fils amount;
  final TextStyle? style;
  final bool showCurrency;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = style ?? theme.textTheme.bodyMedium;
    return Text(
      showCurrency ? amount.aedLabel : amount.aedDisplay,
      style: base?.copyWith(
        fontWeight: emphasise
            ? FontWeight.w700
            : (base.fontWeight ?? FontWeight.w500),
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        color: amount.isNegative ? theme.colorScheme.error : base.color,
      ),
      textAlign: TextAlign.end,
    );
  }
}
