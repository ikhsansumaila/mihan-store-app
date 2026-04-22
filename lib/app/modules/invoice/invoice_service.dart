import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'invoice_controller.dart';

class InvoiceService {
  static Future<File> _generatePdfFile(InvoiceController c) async {
    final pdf = pw.Document();

    final logo = await rootBundle.load('assets/logo.png');
    final logoImage = pw.MemoryImage(logo.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            /// HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Image(logoImage, width: 40),
                    pw.SizedBox(width: 8),
                    pw.Text("MIHANstore", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Text("INVOICE", style: pw.TextStyle(fontSize: 22)),
              ],
            ),

            pw.SizedBox(height: 16),

            pw.Text("Invoice To: ${c.customerName.value}"),
            pw.Text("Date: ${DateFormat('d MMM yyyy').format(DateTime.now())}"),

            pw.SizedBox(height: 16),

            /// TABLE HEADER
            pw.Container(
              color: PdfColors.orange,
              padding: pw.EdgeInsets.all(6),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text("Produk"), pw.Text("Qty"), pw.Text("Harga"), pw.Text("Total")],
              ),
            ),

            /// ITEMS
            ...c.items.map(
              (e) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(e.name),
                    pw.Text("${e.qty}"),
                    pw.Text("Rp ${e.price}"),
                    pw.Text("Rp ${e.total}"),
                  ],
                ),
              ),
            ),

            pw.Divider(),

            /// TOTAL
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [pw.Text("TOTAL"), pw.Text("Rp ${c.total}")],
            ),

            pw.SizedBox(height: 20),

            pw.Text("PEMBAYARAN KE:"),
            pw.Text("BCA"),
            pw.Text("3452271335"),
            pw.Text("QOMARIAH AKMALA"),

            pw.SizedBox(height: 20),

            pw.Container(
              padding: pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.red, width: 2)),
              child: pw.Text("LUNAS", style: pw.TextStyle(color: PdfColors.red, fontSize: 18)),
            ),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf");

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// PREVIEW
  static Future<void> generateAndPreview(InvoiceController c) async {
    final file = await _generatePdfFile(c);
    await Printing.layoutPdf(onLayout: (_) => file.readAsBytes());
  }

  /// SHARE (WhatsApp)
  static Future<void> generateAndShare(InvoiceController c) async {
    final file = await _generatePdfFile(c);

    await Share.shareXFiles([XFile(file.path)], text: "Invoice untuk ${c.customerName.value}");
  }
}
