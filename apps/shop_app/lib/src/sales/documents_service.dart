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
}
