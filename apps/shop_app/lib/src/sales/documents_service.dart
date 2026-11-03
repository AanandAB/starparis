import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:starparis_documents/starparis_documents.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../app_config.dart';

/// Turns a stored order into a document on disk.
///
/// Documents are regenerated from the order every time rather than stored as
/// files: the order carries a frozen breakdown, so regenerating is both cheaper
/// and always consistent. Files land in the shop's documents folder with a
/// predictable name, which is what staff actually look for.
class DocumentsService {
  DocumentsService({required this.db});

  final LocalDatabase db;

  Future<Directory> _outputDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(base.path, 'StarParis'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<File> quoteFor(Order order) async {
    final items = await db.itemsFor(order.id);
    final bytes = await buildQuotePdf(
      QuoteDocument(
        number: order.isQuote
            ? order.numberDisplay
            : 'QT-${order.numberDisplay}',
        issuedAt: order.createdAt,
        validUntil: order.createdAt.add(const Duration(days: 7)),
        customerName: order.customerName ?? 'Customer',
        customerPhone: await db.primaryPhoneFor(order.customerId),
        lines: <DocumentLine>[
          for (final item in items)
            DocumentLine(
              description: item.description,
              quantity: item.quantity,
              unitFils: item.quantity <= 0
                  ? item.subtotalFils
                  : (item.subtotalFils / item.quantity).round(),
              amountFils: item.subtotalFils,
            ),
        ],
        subtotalFils: order.subtotalFils,
        vatFils: order.vatFils,
        totalFils: order.totalFils,
        vatBps: order.subtotalFils == 0
            ? 500
            : ((order.vatFils * 10000) / order.subtotalFils).round(),
        notes: order.notes ?? '',
      ),
      AppConfig.company,
    );
    return _write('Quote-${order.numberDisplay}.pdf', bytes);
  }

  Future<File> jobTicketFor(Order order) async {
    final items = await db.itemsFor(order.id);
    final specifications = <String>[for (final item in items) item.description];
    if (specifications.isEmpty) {
      specifications.add('No line items recorded');
    }

    final bytes = await buildJobTicketPdf(
      JobTicketDocument(
        number: order.numberDisplay,
        createdAt: order.createdAt,
        customerName: order.customerName ?? 'Customer',
        specifications: specifications,
        quantity: items.fold<int>(0, (sum, item) => sum + item.quantity),
        dueAt: order.dueAt,
        priority: order.priority,
        notes: order.notes ?? '',
        isQuote: order.isQuote,
        trackUrl: '${AppConfig.jobQrPrefix}${order.numberDisplay}',
      ),
      AppConfig.company,
    );
    return _write('Job-${order.numberDisplay}.pdf', bytes);
  }

  Future<File> _write(String name, List<int> bytes) async {
    final directory = await _outputDirectory();
    final file = File(p.join(directory.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// The tax invoice, rebuilt from the stored snapshot. The printed numbers come
  /// from the invoice row, never from the order or the current price book.
  Future<File> invoiceFor(Invoice invoice) async {
    final lines = await db.linesFor(invoice.id);
    final bytes = await buildInvoicePdf(
      InvoiceDocument(
        number: invoice.number,
        issuedAt: invoice.issuedAt,
        dueAt: invoice.dueAt,
        customerName: invoice.customerName,
        customerTrn: invoice.customerTrn,
        customerAddress: invoice.customerAddress,
        lines: <DocumentLine>[
          for (final line in lines)
            DocumentLine(
              description: line.description,
              quantity: line.quantity,
              unitFils: line.unitFils,
              amountFils: line.amountFils,
            ),
        ],
        subtotalFils: invoice.subtotalFils,
        discountFils: invoice.discountFils,
        vatBps: invoice.vatBps,
        vatFils: invoice.vatFils,
        totalFils: invoice.totalFils,
        paidFils: invoice.paidFils,
        notes: invoice.notes ?? '',
      ),
      AppConfig.company,
    );
    return _write('${invoice.number}.pdf', bytes);
  }

  /// The credit note, printed as its own document against the invoice.
  Future<File> creditNoteFor(CreditNote note, Invoice invoice) async {
    final bytes = await buildInvoicePdf(
      InvoiceDocument(
        number: note.number,
        issuedAt: note.issuedAt,
        customerName: invoice.customerName,
        customerTrn: invoice.customerTrn,
        customerAddress: invoice.customerAddress,
        lines: <DocumentLine>[
          DocumentLine(
            description: 'Credit - ${note.reason}',
            quantity: 1,
            unitFils: note.subtotalFils,
            amountFils: note.subtotalFils,
          ),
        ],
        subtotalFils: note.subtotalFils,
        vatBps: note.vatBps,
        vatFils: note.vatFils,
        totalFils: note.totalFils,
        documentTitle: 'CREDIT NOTE',
        reference: invoice.number,
        showPayments: false,
      ),
      AppConfig.company,
    );
    return _write('${note.number}.pdf', bytes);
  }
}
