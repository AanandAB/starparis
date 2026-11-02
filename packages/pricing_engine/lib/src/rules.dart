/// Turning one price-book rule into one amount, with a human explanation.
///
/// Kept separate from the engine so the arithmetic for each basis can be tested
/// on its own: a `per_sqm` rate that is one fil out is invisible on a banner
/// quote and obvious on a thousand of them.
library;

import 'package:starparis_domain/starparis_domain.dart';

import 'errors.dart';
import 'models.dart';

/// One rule, evaluated: how many units, how much money, and how to say it out
/// loud to a customer.
final class RuleEvaluation {
  const RuleEvaluation({
    required this.quantity,
    required this.amount,
    required this.explain,
  });

  final int quantity;
  final Fils amount;
  final String explain;
}

/// Evaluates rules against the quantities that matter for the job.
///
/// [runningSubtotal] is the amount accumulated so far in the current phase,
/// which is what `percent_of_subtotal` rules multiply.
final class RuleEvaluator {
  const RuleEvaluator({
    required this.sheets,
    required this.sides,
    required this.quantity,
    required this.areaMilliSqm,
    required this.hours,
    required this.runningSubtotal,
  });

  /// Billable sheets (trim + setup + spoilage).
  final int sheets;
  final int sides;
  final int quantity;

  /// Area in thousandths of a square metre, so 6 m² is 6000.
  final int areaMilliSqm;

  final int hours;
  final Fils runningSubtotal;

  RuleEvaluation evaluate(PriceRule rule) {
    final rate = Fils(rule.rateFils);

    final (int units, Fils amount, String detail) = switch (rule.basis) {
      RuleBasis.flat => (1, rate, 'flat charge'),
      RuleBasis.perSheet => (
          sheets,
          rate * sheets,
          '$sheets ${_plural(sheets, 'sheet')} × ${rate.aedLabel}',
        ),
      RuleBasis.perSheetSide => (
          sheets * sides,
          rate * (sheets * sides),
          '$sheets ${_plural(sheets, 'sheet')} × $sides '
              '${_plural(sides, 'side')} × ${rate.aedLabel}',
        ),
      RuleBasis.perPiece => (
          quantity,
          rate * quantity,
          '$quantity ${_plural(quantity, 'piece')} × ${rate.aedLabel}',
        ),
      RuleBasis.perSqm => (
          areaMilliSqm,
          Fils(mulDivRoundHalfUp(rule.rateFils, areaMilliSqm, 1000)),
          '${_sqm(areaMilliSqm)} m² × ${rate.aedLabel}',
        ),
      RuleBasis.perHour => (
          hours,
          rate * hours,
          '$hours ${_plural(hours, 'hour')} × ${rate.aedLabel}',
        ),
      RuleBasis.percentOfSubtotal => (
          1,
          runningSubtotal.timesBps(rule.rateFils),
          '${_percent(rule.rateFils)} of ${runningSubtotal.aedLabel}',
        ),
    };

    if (rule.minChargeFils > 0 && amount.raw < rule.minChargeFils) {
      return RuleEvaluation(
        quantity: units,
        amount: Fils(rule.minChargeFils),
        explain: '${rule.label}: minimum ${Fils(rule.minChargeFils).aedLabel}',
      );
    }

    if (amount.isNegative) {
      throw PricingException(
        'RULE_NEGATIVE',
        'Rule ${rule.id} produced a negative amount.',
      );
    }

    return RuleEvaluation(quantity: units, amount: amount, explain: detail);
  }

  static String _plural(int count, String noun) => count == 1 ? noun : '${noun}s';

  /// 6000 → "6.000", 1250 → "1.250". Three decimals, because vinyl is sold by
  /// the part square metre and rounding it to two loses money on every roll.
  static String _sqm(int milliSqm) {
    final whole = milliSqm ~/ 1000;
    final fraction = (milliSqm % 1000).toString().padLeft(3, '0');
    return '$whole.$fraction';
  }

  /// 2500 bps → "25%", 750 bps → "7.5%".
  static String _percent(int bps) {
    final whole = bps ~/ 100;
    final fraction = bps % 100;
    if (fraction == 0) {
      return '$whole%';
    }
    final text = fraction.toString().padLeft(2, '0').replaceAll(RegExp(r'0$'), '');
    return '$whole.$text%';
  }
}
