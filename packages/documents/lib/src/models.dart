/// What a document needs to know. Deliberately flat: these are values copied
/// from a stored order at the moment of printing, so a later price change
/// cannot alter a document that has already been handed over.
library;

class CompanyProfile {
  const CompanyProfile({
    required this.name,
    required this.trn,
    required this.address,
    required this.phone,
    this.email,
    this.branchName,
  });

  final String name;

  /// UAE Tax Registration Number. Printed on every tax invoice.
  final String trn;
  final String address;
  final String phone;
  final String? email;
  final String? branchName;
}

class DocumentLine {
  const DocumentLine({
    required this.description,
    required this.quantity,
    required this.unitFils,
    required this.amountFils,
  });

  final String description;
  final int quantity;

  /// Unit price in fils. May be the rounded line price divided by quantity, so
  /// the printed arithmetic always adds up.
  final int unitFils;
  final int amountFils;
}

class QuoteDocument {
  const QuoteDocument({
    required this.number,
    required this.issuedAt,
    required this.validUntil,
    required this.customerName,
    required this.lines,
    required this.subtotalFils,
    required this.vatFils,
    required this.totalFils,
    required this.vatBps,
    this.customerCompany,
    this.customerPhone,
    this.customerTrn,
    this.notes = '',
    this.terms =
        'Prices are valid until the date shown. '
        'Artwork must be supplied print-ready; changes after proof approval '
        'may be charged.',
  });

  final String number;
  final DateTime issuedAt;
  final DateTime validUntil;
  final String customerName;
  final String? customerCompany;
  final String? customerPhone;
  final String? customerTrn;
  final List<DocumentLine> lines;
  final int subtotalFils;
  final int vatFils;
  final int totalFils;
  final int vatBps;
  final String notes;
  final String terms;
}

class JobTicketDocument {
  const JobTicketDocument({
    required this.number,
    required this.createdAt,
    required this.customerName,
    required this.specifications,
    required this.quantity,
    this.dueAt,
    this.priority = 'normal',
    this.notes = '',
    this.isQuote = false,
    this.trackUrl,
  });

  final String number;
  final DateTime createdAt;
  final String customerName;

  /// One line per specification, in the order the production floor reads them:
  /// product, size, paper, sides, finishing.
  final List<String> specifications;
  final int quantity;
  final DateTime? dueAt;
  final String priority;
  final String notes;
  final bool isQuote;

  /// What the printed QR code carries. A ticket that has already been printed
  /// must keep working, so this is stored on the document rather than built
  /// here: the shop can change tracking URLs without reprinting old tickets.
  final String? trackUrl;
}

/// One row of a customer statement: a charge and the money taken against it.
class StatementLine {
  const StatementLine({
    required this.date,
    required this.reference,
    required this.description,
    required this.amountFils,
    required this.paidFils,
    required this.balanceFils,
  });

  /// When the charge happened (the invoice issue date).
  final DateTime date;

  /// The invoice number. Printed so the customer can match rows to bills.
  final String reference;

  final String description;

  /// What the invoice charged, in fils.
  final int amountFils;

  /// Payments and credits taken against the invoice, in fils.
  final int paidFils;

  /// The running account balance AFTER this row, in fils.
  final int balanceFils;
}

/// A statement of account: what a customer was charged, what they paid, and the
/// running balance. Built from invoices already on screen — a statement is a
/// view over existing bills, not new data.
class StatementDocument {
  const StatementDocument({
    required this.customerName,
    required this.lines,
    required this.closingBalanceFils,
    required this.generatedAt,
    this.customerCompany,
    this.customerTrn,
    this.periodLabel = '',
    this.openingBalanceFils = 0,
  });

  final String customerName;
  final String? customerCompany;
  final String? customerTrn;

  /// Branch and/or period shown under the title, e.g. 'Sharjah - Nov 2026'.
  final String periodLabel;

  final int openingBalanceFils;
  final List<StatementLine> lines;
  final int closingBalanceFils;
  final DateTime generatedAt;
}

/// One line of an 80 mm receipt. A receipt line has no unit price of its own —
/// the counter states what and how many and the amount, and the till slip keeps
/// it legible at 42 characters.
class ReceiptLine {
  const ReceiptLine({
    required this.description,
    required this.quantity,
    required this.amountFils,
  });

  final String description;
  final int quantity;

  /// Line total in fils, VAT already inside the sale's rolled-up VAT line.
  final int amountFils;
}

/// An 80 mm thermal receipt for a walk-in sale. Built from the sale row at the
/// moment it is rung, so a later price change cannot alter a slip already
/// handed over.
class ReceiptDocument {
  const ReceiptDocument({
    required this.shopName,
    required this.number,
    required this.issuedAt,
    required this.lines,
    required this.subtotalFils,
    required this.vatFils,
    required this.totalFils,
    required this.paymentMethod,
    this.tenderedFils,
    this.branchName,
    this.address,
    this.phone,
    this.thankYou = 'Thank you',
  });

  final String shopName;
  final String number;
  final DateTime issuedAt;
  final List<ReceiptLine> lines;
  final int subtotalFils;
  final int vatFils;
  final int totalFils;

  /// 'cash' | 'card' | 'transfer'.
  final String paymentMethod;

  /// Cash only: the amount handed over, so the slip can print the change.
  final int? tenderedFils;
  final String? branchName;
  final String? address;
  final String? phone;
  final String thankYou;
}
