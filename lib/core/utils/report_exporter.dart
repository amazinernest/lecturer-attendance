import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../shared/models/course.dart';
import '../../shared/models/student.dart';
import '../../shared/models/attendance_session.dart';
import '../../shared/models/attendance_record.dart';
import 'attendance_calculator.dart';

class ReportExporter {
  ReportExporter._();

  /// Generates a structured PDF document for attendance report
  static Future<Uint8List> generatePdfReport({
    required Course course,
    required List<Student> students,
    required List<AttendanceSession> sessions,
    required List<AttendanceRecord> records,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');

    // Build session records map: sessionId -> studentId -> isPresent
    final recordMap = <String, Map<String, bool>>{};
    for (final r in records) {
      recordMap.putIfAbsent(r.attendanceSessionId, () => {})[r.studentId] = (r.status == AttendanceStatus.present);
    }

    final headers = ['S/N', 'Student Name', 'Matric Number', 'Attended', '%'];

    final rows = <List<String>>[];
    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      int attendedCount = 0;
      for (final sess in sessions) {
        if (recordMap[sess.id]?[s.id] == true) {
          attendedCount++;
        }
      }
      final pct = AttendanceCalculator.calculatePercentage(attendedCount, sessions.length);

      rows.add([
        '${i + 1}',
        s.name,
        s.matricNumber,
        '$attendedCount / ${sessions.length}',
        '${pct.toStringAsFixed(1)}%',
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'LECTURER ATTENDANCE REPORT',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                    ),
                  ),
                  pw.Text(
                    dateFormat.format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.indigo900),
              pw.SizedBox(height: 8),
              pw.Text(
                '${course.courseCode} — ${course.courseTitle}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Department: ${course.department} | Level: ${course.level} | Semester: ${course.semester} (${course.academicSession})',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
              ),
              pw.Text(
                'Total Students: ${students.length} | Classes Held: ${sessions.length} / ${course.expectedClasses}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Lecturer Attendance App', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
              columnWidths: {
                0: const pw.FixedColumnWidth(30),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FixedColumnWidth(60),
                4: const pw.FixedColumnWidth(50),
              },
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a structured Excel spreadsheet for attendance report
  static Uint8List generateExcelReport({
    required Course course,
    required List<Student> students,
    required List<AttendanceSession> sessions,
    required List<AttendanceRecord> records,
  }) {
    final excel = Excel.createExcel();
    final Sheet sheet = excel[excel.getDefaultSheet() ?? 'Attendance'];

    // Record map: sessionId -> studentId -> isPresent
    final recordMap = <String, Map<String, bool>>{};
    for (final r in records) {
      recordMap.putIfAbsent(r.attendanceSessionId, () => {})[r.studentId] = (r.status == AttendanceStatus.present);
    }

    // Title Block
    sheet.appendRow([TextCellValue('Course Code:'), TextCellValue(course.courseCode)]);
    sheet.appendRow([TextCellValue('Course Title:'), TextCellValue(course.courseTitle)]);
    sheet.appendRow([TextCellValue('Academic Session:'), TextCellValue(course.academicSession)]);
    sheet.appendRow([TextCellValue('Total Classes Held:'), TextCellValue('${sessions.length}')]);
    sheet.appendRow([]); // Blank line

    // Header Row: S/N | Name | Matric Number | Class 1 | Class 2 | ... | Total | Percentage
    final headers = <CellValue>[
      TextCellValue('S/N'),
      TextCellValue('Student Name'),
      TextCellValue('Matric Number'),
    ];

    for (int i = 0; i < sessions.length; i++) {
      headers.add(TextCellValue('Class ${sessions[i].classNumber}'));
    }
    headers.add(TextCellValue('Total Attended'));
    headers.add(TextCellValue('Percentage (%)'));

    sheet.appendRow(headers);

    // Rows
    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      final row = <CellValue>[
        TextCellValue('${i + 1}'),
        TextCellValue(s.name),
        TextCellValue(s.matricNumber),
      ];

      int attended = 0;
      for (final sess in sessions) {
        final isPresent = (recordMap[sess.id]?[s.id] == true);
        if (isPresent) attended++;
        row.add(TextCellValue(isPresent ? 'P' : 'A'));
      }

      final pct = AttendanceCalculator.calculatePercentage(attended, sessions.length);
      row.add(TextCellValue('$attended'));
      row.add(TextCellValue('${pct.toStringAsFixed(1)}%'));

      sheet.appendRow(row);
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? []);
  }

  /// Print or share PDF directly
  static Future<void> printOrSharePdf({
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: '$filename.pdf');
  }

  /// Save bytes to a temp file and share it (used for Excel and other non-PDF formats)
  static Future<void> shareFile({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    // Use Printing.sharePdf for sharing any file via the system share sheet
    // For Excel we use the system share mechanism via path
    await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
    );
  }
}
