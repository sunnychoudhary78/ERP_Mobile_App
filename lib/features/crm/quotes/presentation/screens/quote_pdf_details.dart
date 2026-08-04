import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds a print-ready, A4-formatted PDF for a sales quote.
///
/// Kept framework-agnostic (no Riverpod / BuildContext) so it can be unit
/// tested and reused from anywhere — the detail screen, a "resend quote"
/// background job, etc.
class QuotePdfService {
  static Future<Uint8List> generate(dynamic quote) async {
    final doc = pw.Document();

    final quoteNumber = (quote.number ?? quote.id ?? 'QT-2026-0081').toString();
    final account = (quote.account ?? 'Abhinav Company').toString();
    // TODO: wire this to the real client email once the quote model exposes one
    const email = 'deepanshu@gmail.com';

    String status = 'APPROVED';
    if (quote.approval != null && quote.approval is Map && quote.approval['status'] != null) {
      status = quote.approval['status'].toString().toUpperCase();
    } else if (quote.status != null) {
      status = quote.status.toString().toUpperCase();
    }

    final items = _extractItems(quote);
    final totalText = quote.amount != null ? '₹${quote.amount}' : '₹10,62,000';

    final primary = PdfColor.fromHex('#1B4F72');
    final muted = PdfColor.fromHex('#5D6D7E');
    final border = PdfColor.fromHex('#E5E8EB');
    final headerBg = PdfColor.fromHex('#F7F9FC');

    // Google Fonts build (via pdf_google_fonts is not a dependency here) —
    // use the bundled Helvetica-equivalent base font, which renders
    // identically on Android, iOS and Web since text is drawn as vector
    // paths inside the PDF rather than relying on the OS font stack.
    final baseFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        header: (context) => _buildHeader(quoteNumber, primary, muted),
        footer: (context) => _buildFooter(context, muted),
        build: (context) => [
          pw.SizedBox(height: 8),
          _buildStatusAndClient(status, account, email, muted, border),
          pw.SizedBox(height: 20),
          pw.Text(
            'LINE ITEMS',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#85929E')),
          ),
          pw.SizedBox(height: 8),
          // pw.Table is a spanning widget — placed directly in the MultiPage
          // content list (not nested inside a fixed-height container) it
          // will automatically wrap onto new A4 pages for long quotes.
          _buildItemsTable(items, border),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Total   ', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.Text(totalText, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: primary)),
            ],
          ),
          pw.SizedBox(height: 24),
          _buildNote(muted, headerBg),
        ],
      ),
    );

    return doc.save();
  }

  static List<Map<String, String>> _extractItems(dynamic quote) {
    try {
      final rawItems = quote.items;
      if (rawItems is List && rawItems.isNotEmpty) {
        return rawItems.map<Map<String, String>>((item) {
          return {
            'title': (item.title ?? item.name ?? 'Item').toString(),
            'qty': 'Qty: ${item.qty ?? item.quantity ?? 1}',
            'price': item.price != null ? '₹${item.price}' : '₹0',
          };
        }).toList();
      }
    } catch (_) {
      // Quote model doesn't expose an items list yet — fall through to the
      // same demo rows the on-screen card shows, so PDF and screen match.
    }
    return [
      {'title': 'Iphone 18', 'qty': 'Qty: 1', 'price': '₹9,00,000'},
      {'title': 'Pro Care Package', 'qty': 'Qty: 1', 'price': '₹1,62,000'},
    ];
  }

  static pw.Widget _buildHeader(String quoteNumber, PdfColor primary, PdfColor muted) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: primary, width: 1.2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(quoteNumber, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: primary)),
              pw.SizedBox(height: 2),
              pw.Text('Quotation Details', style: pw.TextStyle(fontSize: 10.5, color: muted)),
            ],
          ),
          pw.Text('IMMORTAL ERP', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primary)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, PdfColor muted) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 9, color: muted),
      ),
    );
  }

  static pw.Widget _buildStatusAndClient(
    String status,
    String account,
    String email,
    PdfColor muted,
    PdfColor border,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: border), borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration:
                pw.BoxDecoration(color: PdfColor.fromHex('#A9DFBF'), borderRadius: pw.BorderRadius.circular(10)),
            child: pw.Text(
              status,
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E8449')),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'CLIENT INFORMATION',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#85929E')),
          ),
          pw.SizedBox(height: 10),
          _infoLine('Account', account, muted),
          pw.SizedBox(height: 6),
          _infoLine('Email', email, muted),
        ],
      ),
    );
  }

  static pw.Widget _infoLine(String label, String value, PdfColor muted) {
    return pw.Row(
      children: [
        pw.SizedBox(width: 70, child: pw.Text(label, style: pw.TextStyle(fontSize: 10, color: muted))),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildItemsTable(List<Map<String, String>> items, PdfColor border) {
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: border, width: 0.5),
        top: pw.BorderSide(color: border),
        bottom: pw.BorderSide(color: border),
        left: pw.BorderSide(color: border),
        right: pw.BorderSide(color: border),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1.3),
        2: pw.FlexColumnWidth(1.8),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F1F3F5')),
          children: [
            _cell('Item', bold: true),
            _cell('Qty', bold: true, align: pw.TextAlign.center),
            _cell('Price', bold: true, align: pw.TextAlign.right),
          ],
        ),
        ...items.map(
          (item) => pw.TableRow(
            children: [
              _cell(item['title'] ?? ''),
              _cell(item['qty'] ?? '', align: pw.TextAlign.center),
              _cell(item['price'] ?? '', align: pw.TextAlign.right),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 10.5, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  static pw.Widget _buildNote(PdfColor muted, PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(color: bg, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Text(
        'Mark the lead won in CRM when the customer accepts, then create a sales order.',
        style: pw.TextStyle(fontSize: 9.5, color: muted),
      ),
    );
  }
}