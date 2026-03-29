import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:hostel_log/models/student.dart';
import 'package:hostel_log/models/log_entry.dart';

class ExcelService {
  static Future<void> generateStudentLogsReport(
      List<Student> students, List<LogEntry> allLogs, int studentsIn, int studentsOut) async {
    
    // Create new Excel document
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // Define headers
    List<CellValue> headers = [
      TextCellValue('Name'),
      TextCellValue('Reg No'),
      TextCellValue('Room No'),
      TextCellValue('Phone'),
      TextCellValue('Last Log Type'),
      TextCellValue('Last Log Date'),
      TextCellValue('Last Log Time'),
    ];
    sheetObject.appendRow(headers);

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

    final DateFormat logDateFormat = DateFormat('MMM dd, yyyy');
    final DateFormat logTimeFormat = DateFormat('hh:mm a');

    // Add student data
    for (var student in students) {
      final latestLog = latestStudentLogs[student.fingerprintId];
      
      String logType = latestLog != null ? latestLog.type.toUpperCase() : 'NO LOGS';
      String logDate = latestLog != null ? logDateFormat.format(latestLog.timestamp) : '-';
      String logTime = latestLog != null ? logTimeFormat.format(latestLog.timestamp) : '-';

      sheetObject.appendRow([
        TextCellValue(student.name),
        TextCellValue(student.regNo),
        TextCellValue(student.roomNo),
        TextCellValue(student.phoneNo),
        TextCellValue(logType),
        TextCellValue(logDate),
        TextCellValue(logTime),
      ]);
    }

    // Add empty row separator
    sheetObject.appendRow([]);

    // Add summary
    sheetObject.appendRow([
      TextCellValue('Total Students IN:'),
      IntCellValue(studentsIn),
    ]);
    sheetObject.appendRow([
      TextCellValue('Total Students OUT:'),
      IntCellValue(studentsOut),
    ]);

    List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
      
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(fileBytes),
          name: 'Student_Logs_Report_$dateStr.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        )
      ], text: 'Hostel Student Logs Report');
    }
  }
}
