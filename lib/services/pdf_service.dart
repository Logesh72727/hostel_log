
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:hostel_log/models/student.dart';
import 'package:hostel_log/models/log_entry.dart';

class PdfService {
  static Future<void> generateStudentLogsReport(
      List<Student> students, List<LogEntry> allLogs, int studentsIn, int studentsOut) async {
    final pdf = pw.Document();

    // Group logs by student to find the single latest log
    final Map<int, LogEntry> latestStudentLogs = {};
    for (var log in allLogs) {
      if (!latestStudentLogs.containsKey(log.fingerprintId)) {
        latestStudentLogs[log.fingerprintId] = log;
      } else {
        if (log.timestamp.isAfter(latestStudentLogs[log.fingerprintId]!.timestamp)) {
          latestStudentLogs[log.fingerprintId] = log;
        }
      }
    }

    final now = DateTime.now();
    final DateFormat dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    final DateFormat logDateFormat = DateFormat('MMM dd, yyyy');
    final DateFormat logTimeFormat = DateFormat('hh:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final titleWidget = pw.Header(
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
          );

          final List<pw.Widget> elements = [
            titleWidget,
            pw.SizedBox(height: 20),
          ];

          if (students.isEmpty) {
            elements.add(pw.Center(child: pw.Text('No students found.')));
          } else {
            elements.add(pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Name', 'Reg No', 'Room No', 'Phone', 'Log Type', 'Date', 'Time'],
              data: students.map((student) {
                final latestLog = latestStudentLogs[student.fingerprintId];
                return [
                  student.name,
                  student.regNo,
                  student.roomNo,
                  student.phoneNo,
                  latestLog != null ? latestLog.type.toUpperCase() : 'NO LOGS',
                  latestLog != null ? logDateFormat.format(latestLog.timestamp) : '-',
                  latestLog != null ? logTimeFormat.format(latestLog.timestamp) : '-',
                ];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo600),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              cellAlignment: pw.Alignment.centerLeft,
            ));
          }

          // Summary section
          elements.add(pw.SizedBox(height: 30));
          elements.add(pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800)),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text('Total Students IN: $studentsIn', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Total Students OUT: $studentsOut', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ));

          return elements;
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Student_Logs_Report_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf');
  }
}
