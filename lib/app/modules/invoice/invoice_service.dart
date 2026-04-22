import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/currency_format.dart';
import 'invoice_controller.dart';

class InvoiceService {
  static Future<File> _generatePdfFile(InvoiceController c) async {
    final pdf = pw.Document();

    final logo = await rootBundle.load('assets/logo.png');
    final logoImage = pw.MemoryImage(logo.buffer.asUint8List());

    final lunas = await rootBundle.load('assets/lunas.png');
    final lunasImage = pw.MemoryImage(lunas.buffer.asUint8List());

    final orangeColor = PdfColor.fromHex('#F2A138');
    final darkGray = PdfColor.fromHex('#333333');

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(0),
        footer: (context) => pw.Container(
          width: double.infinity,
          color: orangeColor,
          padding: const pw.EdgeInsets.symmetric(vertical: 16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                "PT. MIHAN JAYA BERKAH",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                  fontSize: 10,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                "Jl. Masjid Raudhatul Jannah, Sudimara Pinang, Pinang, Tangerang",
                style: const pw.TextStyle(color: PdfColors.black, fontSize: 10),
              ),
            ],
          ),
        ),
        build: (context) => [
          // HEADER
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 32, right: 32, top: 32, bottom: 16),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Image(logoImage, width: 120),
                    // pw.SizedBox(height: 4),
                    // pw.RichText(
                    //   text: pw.TextSpan(
                    //     style: const pw.TextStyle(color: PdfColors.black, fontSize: 14),
                    //     children: [
                    //       pw.TextSpan(
                    //         text: "MIHAN",
                    //         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    //       ),
                    //       const pw.TextSpan(text: "store"),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
                pw.Text(
                  "I N V O I C E",
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: darkGray,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),

          // Orange Line
          pw.Container(height: 2, color: orangeColor, width: double.infinity),

          // Billing Info
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 80,
                      child: pw.Text(
                        "INVOICE TO",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: darkGray,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    pw.Text(
                      ": ${c.customerName.value.toUpperCase()}",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: darkGray,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 80,
                      child: pw.Text(
                        "DATE",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: darkGray,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    pw.Text(
                      ": ${DateFormat('d MMMM yyyy').format(DateTime.now()).toUpperCase()}",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: darkGray,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table Header
          pw.Container(
            color: orangeColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    "NAMA PRODUK",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    "JUMLAH",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 1,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    "HARGA",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 1,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    "TOTAL",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 1,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Table Items
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: pw.Column(
              children: c.items.map((e) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(
                          e.name.toUpperCase(),
                          style: pw.TextStyle(color: darkGray, letterSpacing: 1),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          "${e.qty} PCS",
                          style: pw.TextStyle(color: darkGray, letterSpacing: 1),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          CurrencyFormat.convertToIdr(e.price).toUpperCase(),
                          style: pw.TextStyle(color: darkGray, letterSpacing: 1),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          CurrencyFormat.convertToIdr(e.total).toUpperCase(),
                          style: pw.TextStyle(color: darkGray, letterSpacing: 1),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Line
          pw.Container(height: 2, color: orangeColor, width: double.infinity),

          // Total
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 8,
                  child: pw.Text(
                    "TOTAL",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: darkGray,
                      letterSpacing: 2,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    CurrencyFormat.convertToIdr(c.total).toUpperCase(),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: darkGray,
                      letterSpacing: 1,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Line
          pw.Container(height: 2, color: orangeColor, width: double.infinity),

          // Payment Info
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 32, right: 32, top: 32, bottom: 32),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "PEMBAYARAN KE:",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: darkGray,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      "BCA\n3452271335\nQOMARIAH AKMALA",
                      style: pw.TextStyle(
                        color: darkGray,
                        lineSpacing: 4,
                        letterSpacing: 1,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (c.isLunas.value)
                  pw.Transform.rotate(angle: 0.15, child: pw.Image(lunasImage, width: 200)),
              ],
            ),
          ),
        ],
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
