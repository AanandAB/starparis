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
