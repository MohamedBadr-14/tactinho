import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:tactinho/models/tactic_item.dart';

class TacticsReportPage extends StatelessWidget {
  final List<TacticItem> tactics;

  TacticsReportPage({required this.tactics});



Future<void> _generatePdf(BuildContext context) async {
  final pdf = pw.Document();
  final font = await PdfGoogleFonts.openSansRegular();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Tactics Report',
              style: pw.TextStyle(
                font: font,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          for (var tactic in tactics)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  padding: pw.EdgeInsets.all(16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        tactic.title,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        tactic.description,
                        style: pw.TextStyle(font: font, fontSize: 14),
                      ),
                      pw.SizedBox(height: 12),
                      // 🖼️ Add image
                      if (tactic.imagePath.isNotEmpty)
                        pw.Center(
    child: pw.Image(
      pw.MemoryImage(File(tactic.imagePath).readAsBytesSync()),
      height: 200,
      width: 300,
      fit: pw.BoxFit.contain,
    ),
  ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
              ],
            ),
        ];
      },
    ),
  );

  // Save PDF file

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Tactics_Report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text(
          'Tactics details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor:const Color(0xFF1E6C41),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () => _generatePdf(context),
            tooltip: 'Export as PDF',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: ListView.builder(
          padding: EdgeInsets.all(24),
          itemCount: tactics.length,
          itemBuilder: (context, index) {
            final tactic = tactics[index];
            return Card(
              margin: EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.file(
                     File( tactic.imagePath),
                      fit: BoxFit.contain,
                      height: 200,
                      width: double.infinity,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tactic.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          tactic.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

