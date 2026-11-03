import 'dart:convert';

import 'package:http/http.dart' as http;

/// Reads the two reports the owner and the accountant ask for.
///
/// These are the only numbers in the app that are **not** in the local database:
/// a VAT return and an ageing list are whole-shop questions, and the live D1 is
/// the only place that has every branch's documents. The screen says so
/// explicitly, so nobody mistakes them for offline figures.
class VatSummary {
  const VatSummary({
    required this.from,
    required this.to,
    required this.salesNetFils,
    required this.outputVatFils,
    required this.salesGrossFils,
    required this.invoiceCount,
    required this.creditedNetFils,
    required this.creditedVatFils,
    required this.creditedGrossFils,
    required this.creditNoteCount,
    required this.netVatDueFils,
    required this.collectedFils,
    required this.refundedFils,
    required this.collectedByMethod,
  });

  factory VatSummary.fromJson(Map<String, Object?> json) => VatSummary(
    from: DateTime.parse(json['from']! as String),
    to: DateTime.parse(json['to']! as String),
    salesNetFils: (json['sales_net_fils'] as num?)?.toInt() ?? 0,
    outputVatFils: (json['output_vat_fils'] as num?)?.toInt() ?? 0,
    salesGrossFils: (json['sales_gross_fils'] as num?)?.toInt() ?? 0,
    invoiceCount: (json['invoice_count'] as num?)?.toInt() ?? 0,
    creditedNetFils: (json['credited_net_fils'] as num?)?.toInt() ?? 0,
    creditedVatFils: (json['credited_vat_fils'] as num?)?.toInt() ?? 0,
    creditedGrossFils: (json['credited_gross_fils'] as num?)?.toInt() ?? 0,
    creditNoteCount: (json['credit_note_count'] as num?)?.toInt() ?? 0,
    netVatDueFils: (json['net_vat_due_fils'] as num?)?.toInt() ?? 0,
    collectedFils: (json['collected_fils'] as num?)?.toInt() ?? 0,
    refundedFils: (json['refunded_fils'] as num?)?.toInt() ?? 0,
    collectedByMethod: <String, int>{
      for (final entry
          in ((json['collected_by_method'] as Map?) ??
                  const <String, Object?>{})
              .entries)
        entry.key as String: (entry.value as num?)?.toInt() ?? 0,
    },
  );

  final DateTime from;
  final DateTime to;
  final int salesNetFils;
  final int outputVatFils;
  final int salesGrossFils;
  final int invoiceCount;
  final int creditedNetFils;
  final int creditedVatFils;
  final int creditedGrossFils;
  final int creditNoteCount;
  final int netVatDueFils;
  final int collectedFils;
  final int refundedFils;
  final Map<String, int> collectedByMethod;
}

class AgeingRow {
  const AgeingRow({
    required this.customerId,
    required this.customerName,
    required this.currentFils,
    required this.days3160Fils,
    required this.days6190Fils,
    required this.over90Fils,
    required this.totalFils,
    required this.invoices,
  });

  factory AgeingRow.fromJson(Map<String, Object?> json) => AgeingRow(
    customerId: json['customer_id'] as String? ?? '',
    customerName: json['customer_name'] as String? ?? '',
    currentFils: (json['current_fils'] as num?)?.toInt() ?? 0,
    days3160Fils: (json['days_31_60_fils'] as num?)?.toInt() ?? 0,
    days6190Fils: (json['days_61_90_fils'] as num?)?.toInt() ?? 0,
    over90Fils: (json['over_90_fils'] as num?)?.toInt() ?? 0,
    totalFils: (json['total_fils'] as num?)?.toInt() ?? 0,
    invoices: (json['invoices'] as num?)?.toInt() ?? 0,
  );

  final String customerId;
  final String customerName;
  final int currentFils;
  final int days3160Fils;
  final int days6190Fils;
  final int over90Fils;
  final int totalFils;
  final int invoices;
}

class AgeingReport {
  const AgeingReport({
    required this.asOf,
    required this.rows,
    required this.totals,
  });

  factory AgeingReport.fromJson(Map<String, Object?> json) => AgeingReport(
    asOf: DateTime.tryParse(json['as_of'] as String? ?? '') ?? DateTime.now(),
    rows: <AgeingRow>[
      for (final row
          in (json['buckets'] as List<Object?>? ?? const <Object?>[]))
        AgeingRow.fromJson((row! as Map).cast<String, Object?>()),
    ],
    totals: AgeingRow.fromJson(<String, Object?>{
      'customer_name': 'Total',
      ...(((json['totals'] as Map?) ?? const <String, Object?>{}))
          .cast<String, Object?>(),
    }),
  );

  final DateTime asOf;
  final List<AgeingRow> rows;
  final AgeingRow totals;
}

/// One shift at the counter, as the server recorded it.
class TillShift {
  const TillShift({
    required this.id,
    required this.status,
    required this.openedAt,
    required this.openingFloatFils,
    this.closedAt,
    this.openedBy,
    this.closedBy,
    this.expectedFils,
    this.countedFils,
    this.varianceFils,
  });

  factory TillShift.fromJson(Map<String, Object?> json) {
    int? asInt(String key) => (json[key] as num?)?.toInt();
    return TillShift(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      openedAt: DateTime.parse(json['opened_at'] as String),
      openingFloatFils: asInt('opening_float_fils') ?? 0,
      closedAt: json['closed_at'] == null
          ? null
          : DateTime.parse(json['closed_at'] as String),
      openedBy: json['opened_by_name'] as String?,
      closedBy: json['closed_by_name'] as String?,
      expectedFils: asInt('expected_fils'),
      countedFils: asInt('counted_fils'),
      varianceFils: asInt('variance_fils'),
    );
  }

  final String id;
  final String status;
  final DateTime openedAt;
  final int openingFloatFils;
  final DateTime? closedAt;
  final String? openedBy;
  final String? closedBy;
  final int? expectedFils;
  final int? countedFils;
  final int? varianceFils;

  bool get isShort => (varianceFils ?? 0) < 0;
}

class TillHistory {
  const TillHistory({
    required this.shifts,
    required this.varianceFils,
    required this.shortFils,
  });

  factory TillHistory.fromJson(Map<String, Object?> json) {
    final rows = (json['sessions'] as List<Object?>? ?? const <Object?>[])
        .cast<Map<String, Object?>>();
    return TillHistory(
      shifts: rows.map(TillShift.fromJson).toList(growable: false),
      varianceFils: (json['variance_fils'] as num?)?.toInt() ?? 0,
      shortFils: (json['short_fils'] as num?)?.toInt() ?? 0,
    );
  }

  final List<TillShift> shifts;
  final int varianceFils;
  final int shortFils;
}

/// What the shop paid for, grouped by category.
class ExpenseCategory {
  const ExpenseCategory({
    required this.category,
    required this.entries,
    required this.netFils,
    required this.vatFils,
    required this.totalFils,
  });

  factory ExpenseCategory.fromJson(Map<String, Object?> json) {
    int asInt(String key) => (json[key] as num?)?.toInt() ?? 0;
    return ExpenseCategory(
      category: json['category'] as String? ?? 'Other',
      entries: asInt('entries'),
      netFils: asInt('net_fils'),
      vatFils: asInt('vat_fils'),
      totalFils: asInt('total_fils'),
    );
  }

  final String category;
  final int entries;
  final int netFils;
  final int vatFils;
  final int totalFils;
}

class ExpenseSummary {
  const ExpenseSummary({
    required this.rows,
    required this.vatFils,
    required this.totalFils,
  });

  factory ExpenseSummary.fromJson(Map<String, Object?> json) {
    final rows = (json['rows'] as List<Object?>? ?? const <Object?>[])
        .cast<Map<String, Object?>>();
    return ExpenseSummary(
      rows: rows.map(ExpenseCategory.fromJson).toList(growable: false),
      vatFils: (json['vat_fils'] as num?)?.toInt() ?? 0,
      totalFils: (json['total_fils'] as num?)?.toInt() ?? 0,
    );
  }

  final List<ExpenseCategory> rows;
  final int vatFils;
  final int totalFils;
}

class ReportsService {
  ReportsService({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  Future<VatSummary> vat({required DateTime from, required DateTime to}) async {
    final body = await _get(
      '/v1/reports/vat'
      '?from=${Uri.encodeQueryComponent(from.toUtc().toIso8601String())}'
      '&to=${Uri.encodeQueryComponent(to.toUtc().toIso8601String())}',
    );
    return VatSummary.fromJson(body);
  }

  Future<AgeingReport> ageing({DateTime? asOf}) async {
    final at = asOf ?? DateTime.now();
    final body = await _get(
      '/v1/reports/ageing'
      '?as_of=${Uri.encodeQueryComponent(at.toUtc().toIso8601String())}',
    );
    return AgeingReport.fromJson(body);
  }

  Future<TillHistory> tills({required DateTime from, required DateTime to}) async {
    final body = await _get(
      '/v1/reports/tills'
      '?from=${Uri.encodeQueryComponent(from.toUtc().toIso8601String())}'
      '&to=${Uri.encodeQueryComponent(to.toUtc().toIso8601String())}',
    );
    return TillHistory.fromJson(body);
  }

  Future<ExpenseSummary> expenses({
    required DateTime from,
    required DateTime to,
  }) async {
    final body = await _get(
      '/v1/reports/expenses'
      '?from=${Uri.encodeQueryComponent(from.toUtc().toIso8601String())}'
      '&to=${Uri.encodeQueryComponent(to.toUtc().toIso8601String())}',
    );
    return ExpenseSummary.fromJson(body);
  }

  Future<Map<String, Object?>> _get(String path) async {
    final token = await tokenProvider();
    if (token == null) {
      throw StateError('Sign in again to read reports.');
    }
    final response = await _client
        .get(
          Uri.parse('$baseUrl$path'),
          headers: <String, String>{'authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 403) {
      throw StateError('Your role cannot read the books.');
    }
    if (response.statusCode != 200) {
      throw StateError('Report failed (${response.statusCode}).');
    }
    return (jsonDecode(response.body) as Map).cast<String, Object?>();
  }

  void dispose() => _client.close();
}
