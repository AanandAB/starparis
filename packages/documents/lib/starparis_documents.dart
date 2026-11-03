/// Documents the shop hands to a customer: quotations, job tickets, invoices.
///
/// Pure Dart on top of `package:pdf`, so a document can be generated in an
/// isolate, in a test, or on a server without a Flutter engine. The app wraps
/// these functions and decides where the bytes go.
///
/// Arabic: `pdf` lays out bidirectional text but does not perform OpenType
/// shaping, so Arabic renders with isolated letterforms. That is why the Arabic
/// document work is a separate decision (PLAN.md ADR-009) and this package
/// currently renders English only — a wrong-looking tax invoice is worse than
/// an English one.
library;

export 'src/invoice.dart' show buildInvoicePdf, InvoiceDocument;
export 'src/job_ticket.dart' show buildJobTicketPdf;
export 'src/models.dart';
export 'src/quote.dart' show buildQuotePdf;
