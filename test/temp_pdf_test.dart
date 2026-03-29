import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

void main() {
  test('generate simple pdf', () async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final DateFormat dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Hostel Student Logs Report',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text(dateFormat.format(now),
                        style: const pw.TextStyle(color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Name', 'Reg No', 'Room No', 'Phone', 'Log Type', 'Date', 'Time'],
                data: [
                  ['John Doe', 'REG123', 'Room A1', '123456', 'ENTRY', 'Jan 01, 2024', '10:00 AM']
                ],
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo600),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                cellAlignment: pw.Alignment.centerLeft,
              )
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      expect(bytes.isNotEmpty, true);
    } catch (e, st) {
      fail("PDF Generation failed: $e\n$st");
    }
  });
}
