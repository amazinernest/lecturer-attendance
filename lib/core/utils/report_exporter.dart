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

class _ReportStudentRow {
  final int sn;
  final String name;
  final String matric;
  final int attended;
  final int totalClasses;
  final double percentage;
  final bool isEligible;

  const _ReportStudentRow({
    required this.sn,
    required this.name,
    required this.matric,
    required this.attended,
    required this.totalClasses,
    required this.percentage,
    required this.isEligible,
  });
}

class ReportExporter {
  ReportExporter._();

  /// Generates an executive, institutional PDF document for attendance report & exam eligibility
  static Future<Uint8List> generatePdfReport({
    required Course course,
    required List<Student> students,
    required List<AttendanceSession> sessions,
    required List<AttendanceRecord> records,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('EEEE, d MMMM yyyy');

    // Build session records map: sessionId -> studentId -> isPresent
    final recordMap = <String, Map<String, bool>>{};
    for (final r in records) {
      recordMap.putIfAbsent(r.attendanceSessionId, () => {})[r.studentId] = (r.status == AttendanceStatus.present);
    }

    final totalEnrolled = students.length;
    final classesHeld = sessions.length;
    int qualifiedCount = 0;
    int atRiskCount = 0;
    double totalPctSum = 0;

    final studentRows = <_ReportStudentRow>[];
    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      int attendedCount = 0;
      for (final sess in sessions) {
        if (recordMap[sess.id]?[s.id] == true) {
          attendedCount++;
        }
      }
      final pct = AttendanceCalculator.calculatePercentage(attendedCount, classesHeld);
      totalPctSum += pct;
      final isEligible = classesHeld == 0 || pct >= 75.0;
      if (classesHeld > 0) {
        if (isEligible) {
          qualifiedCount++;
        } else {
          atRiskCount++;
        }
      }

      studentRows.add(_ReportStudentRow(
        sn: i + 1,
        name: s.name,
        matric: s.matricNumber,
        attended: attendedCount,
        totalClasses: classesHeld,
        percentage: pct,
        isEligible: isEligible,
      ));
    }

    final classAverage = totalEnrolled > 0 ? (totalPctSum / totalEnrolled) : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Top Institutional Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF0F2248),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'OFFICIAL COURSE ATTENDANCE MATRIX & ELIGIBILITY REPORT',
                          style: pw.TextStyle(
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${course.courseCode} - ${course.courseTitle}',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF7DD3FC),
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF1E3A8A),
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        '${course.academicSession} | ${course.semester} SEMESTER',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 8),

              // Course metadata line
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Department: ${course.department} | Level: ${course.level}',
                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                  ),
                  pw.Text(
                    'Generated on: ${dateFormat.format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),

              // 4 Executive KPI Metric Cards (Shown on page 1)
              if (context.pageNumber == 1) ...[
                pw.Row(
                  children: [
                    _kpiCard('ENROLLED STUDENTS', '$totalEnrolled', 'Class Roster', PdfColors.blue900),
                    pw.SizedBox(width: 8),
                    _kpiCard('CLASSES HELD', '$classesHeld of ${course.expectedClasses}', 'Sessions', PdfColors.indigo900),
                    pw.SizedBox(width: 8),
                    _kpiCard(
                      'CLASS AVERAGE',
                      '${classAverage.toStringAsFixed(1)}%',
                      'Overall Rate',
                      classAverage >= 75.0 ? PdfColors.green800 : PdfColors.amber800,
                    ),
                    pw.SizedBox(width: 8),
                    _kpiCard(
                      'EXAM QUALIFIED (>=75%)',
                      classesHeld > 0 ? '$qualifiedCount / $totalEnrolled' : 'Pending',
                      classesHeld > 0 ? '$atRiskCount Deficient' : 'No classes held',
                      atRiskCount == 0 ? PdfColors.green800 : PdfColors.red800,
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
              ],
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Lecturer Attendance System | Official Institutional Record',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Styled Data Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
              columnWidths: {
                0: const pw.FixedColumnWidth(26),
                1: const pw.FlexColumnWidth(3.2),
                2: const pw.FlexColumnWidth(2.3),
                3: const pw.FixedColumnWidth(65),
                4: const pw.FixedColumnWidth(55),
                5: const pw.FixedColumnWidth(80),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0F2248)),
                  children: [
                    _cellHeader('S/N'),
                    _cellHeader('Student Full Name', alignLeft: true),
                    _cellHeader('Matric Number', alignLeft: true),
                    _cellHeader('Attended'),
                    _cellHeader('Rate (%)'),
                    _cellHeader('Exam Status'),
                  ],
                ),
                // Data Rows with alternating backgrounds
                for (int i = 0; i < studentRows.length; i++)
                  _buildStudentTableRow(studentRows[i], i),
              ],
            ),

            pw.SizedBox(height: 18),

            // Sign-off verification block
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                color: const PdfColor.fromInt(0xFFFAFAFA),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INSTITUTIONAL VERIFICATION & ENDORSEMENT',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _signatureBlock('Course Lecturer', 'Sign & Date: ___________________'),
                      _signatureBlock('Head of Department (HOD)', 'Sign & Date: ___________________'),
                      _signatureBlock('Dean / Exams Officer', 'Stamp & Date: __________________'),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a single class session attendance sheet PDF (Daily Session Report)
  static Future<Uint8List> generateSessionAttendancePdf({
    required Course course,
    required AttendanceSession session,
    required List<Student> students,
    required Map<String, AttendanceStatus> attendanceMap,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('EEEE, d MMMM yyyy');

    final totalEnrolled = students.length;
    int presentCount = 0;
    int absentCount = 0;

    for (final s in students) {
      if (attendanceMap[s.id] == AttendanceStatus.present) {
        presentCount++;
      } else {
        absentCount++;
      }
    }

    final ratePct = totalEnrolled > 0 ? (presentCount / totalEnrolled * 100) : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF0F2248),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DAILY CLASS ATTENDANCE LOG',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${course.courseCode} - ${course.courseTitle}',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF7DD3FC),
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF1E3A8A),
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        'CLASS #${session.classNumber}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 8),

              // Session Info Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF1F5F9),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Row(
                  children: [
                    pw.Text('TOPIC: ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                    pw.Expanded(
                      child: pw.Text(
                        session.topic.isNotEmpty ? session.topic : 'Regular Lecture',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
                      ),
                    ),
                    pw.Text(
                      'DATE: ${dateFormat.format(session.date)}',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 8),

              // KPI Row for Single Session
              if (context.pageNumber == 1) ...[
                pw.Row(
                  children: [
                    _kpiCard('ENROLLED', '$totalEnrolled', 'Students', PdfColors.blue900),
                    pw.SizedBox(width: 8),
                    _kpiCard('PRESENT', '$presentCount', 'Marked Present', PdfColors.green800),
                    pw.SizedBox(width: 8),
                    _kpiCard('ABSENT', '$absentCount', 'Marked Absent', absentCount > 0 ? PdfColors.red800 : PdfColors.grey700),
                    pw.SizedBox(width: 8),
                    _kpiCard('ATTENDANCE RATE', '${ratePct.toStringAsFixed(1)}%', 'Attendance', ratePct >= 75.0 ? PdfColors.green800 : PdfColors.amber800),
                  ],
                ),
                pw.SizedBox(height: 10),
              ],
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Lecturer Attendance System | Daily Class Record',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
              columnWidths: {
                0: const pw.FixedColumnWidth(26),
                1: const pw.FlexColumnWidth(3.5),
                2: const pw.FlexColumnWidth(2.5),
                3: const pw.FixedColumnWidth(70),
                4: const pw.FixedColumnWidth(90),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0F2248)),
                  children: [
                    _cellHeader('S/N'),
                    _cellHeader('Student Full Name', alignLeft: true),
                    _cellHeader('Matric Number', alignLeft: true),
                    _cellHeader('Status'),
                    _cellHeader('Verification Note'),
                  ],
                ),
                for (int i = 0; i < students.length; i++)
                  _buildSingleSessionRow(students[i], i, attendanceMap[students[i].id] == AttendanceStatus.present),
              ],
            ),

            pw.SizedBox(height: 18),

            // Lecturer Certification Block
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                color: const PdfColor.fromInt(0xFFFAFAFA),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LECTURER CERTIFICATION',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'I hereby certify that this attendance record accurately reflects physical/verified presence for this lecture.',
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Signature: ______________________', style: const pw.TextStyle(fontSize: 7.5)),
                      pw.SizedBox(height: 4),
                      pw.Text('Date: _________________________', style: const pw.TextStyle(fontSize: 7.5)),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _kpiCard(String label, String value, String sub, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFF1F5F9),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1), width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color),
            ),
            pw.SizedBox(height: 1),
            pw.Text(sub, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _cellHeader(String text, {bool alignLeft = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.TableRow _buildStudentTableRow(_ReportStudentRow row, int index) {
    final isEven = (index % 2 == 0);
    final bgColor = isEven ? PdfColors.white : const PdfColor.fromInt(0xFFF8FAFC);

    final statusBg = row.totalClasses == 0
        ? const PdfColor.fromInt(0xFFE2E8F0)
        : (row.isEligible ? const PdfColor.fromInt(0xFFD1FAE5) : const PdfColor.fromInt(0xFFFEE2E2));
    final statusColor = row.totalClasses == 0
        ? PdfColors.grey800
        : (row.isEligible ? const PdfColor.fromInt(0xFF065F46) : const PdfColor.fromInt(0xFF991B1B));
    final statusText = row.totalClasses == 0
        ? 'PENDING'
        : (row.isEligible ? 'QUALIFIED' : 'DEFICIENT');

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bgColor),
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          alignment: pw.Alignment.center,
          child: pw.Text('${row.sn}', style: const pw.TextStyle(fontSize: 7.5)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            row.name,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            row.matric,
            style: const pw.TextStyle(fontSize: 7.5),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          alignment: pw.Alignment.center,
          child: pw.Text('${row.attended} / ${row.totalClasses}', style: const pw.TextStyle(fontSize: 7.5)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          alignment: pw.Alignment.center,
          child: pw.Text(
            '${row.percentage.toStringAsFixed(1)}%',
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: (row.totalClasses > 0 && !row.isEligible) ? PdfColors.red800 : PdfColors.black,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          alignment: pw.Alignment.center,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: pw.BoxDecoration(
              color: statusBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Text(
              statusText,
              style: pw.TextStyle(fontSize: 6.8, fontWeight: pw.FontWeight.bold, color: statusColor),
            ),
          ),
        ),
      ],
    );
  }

  static pw.TableRow _buildSingleSessionRow(Student student, int index, bool isPresent) {
    final isEven = (index % 2 == 0);
    final bgColor = isEven ? PdfColors.white : const PdfColor.fromInt(0xFFF8FAFC);
    final statusBg = isPresent ? const PdfColor.fromInt(0xFFD1FAE5) : const PdfColor.fromInt(0xFFFEE2E2);
    final statusColor = isPresent ? const PdfColor.fromInt(0xFF065F46) : const PdfColor.fromInt(0xFF991B1B);
    final statusText = isPresent ? 'PRESENT' : 'ABSENT';

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bgColor),
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          alignment: pw.Alignment.center,
          child: pw.Text('${index + 1}', style: const pw.TextStyle(fontSize: 7.5)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            student.name,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(student.matricNumber, style: const pw.TextStyle(fontSize: 7.5)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          alignment: pw.Alignment.center,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: pw.BoxDecoration(
              color: statusBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Text(
              statusText,
              style: pw.TextStyle(fontSize: 6.8, fontWeight: pw.FontWeight.bold, color: statusColor),
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          alignment: pw.Alignment.center,
          child: pw.Text(
            isPresent ? 'Verified' : 'Unexcused',
            style: pw.TextStyle(
              fontSize: 7,
              color: isPresent ? PdfColors.grey700 : PdfColors.red700,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _signatureBlock(String title, String prompt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.SizedBox(height: 4),
        pw.Text(prompt, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
      ],
    );
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

  /// Generates a printable official institutional QR Attendance Sheet (A4 PDF)
  static Future<Uint8List> generateQrAttendanceSheetPdf({
    required Course course,
    required int classNumber,
    required String topic,
    required DateTime date,
    required String qrData,
    String? pinCode,
    required int totalStudents,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('EEEE, d MMMM yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'OFFICIAL CLASS ATTENDANCE SHEET',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '${course.courseCode} - ${course.courseTitle}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Dept: ${course.department} | Level: ${course.level} | ${course.academicSession}',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.blue300, width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'CLASS #$classNumber',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          dateFormat.format(date),
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1.5, color: PdfColors.blue900),
              pw.SizedBox(height: 8),

              // Topic / Module Strip
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  children: [
                    pw.Text('TOPIC / MODULE: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                    pw.Expanded(
                      child: pw.Text(topic.isNotEmpty ? topic : 'Regular Academic Lecture', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
                    ),
                    pw.Text('ENROLLED: $totalStudents STUDENTS', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Main QR Box & Instructions
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.blue200, width: 1.2),
                  color: PdfColors.blue50.flatten(),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Barcode QR
                    pw.Container(
                      width: 135,
                      height: 135,
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: qrData,
                        width: 123,
                        height: 123,
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    // Instructions & PIN
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'STUDENT SIGN-IN INSTRUCTIONS',
                            style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                          ),
                          pw.SizedBox(height: 6),
                          _pdfInstructionRow('1', 'Scan QR code with your smartphone camera or browser.'),
                          _pdfInstructionRow('2', 'Select your name or enter your Student Matriculation Number.'),
                          if (pinCode != null && pinCode.isNotEmpty) ...[
                            _pdfInstructionRow('3', 'Enter the 4-Digit Security Session PIN:'),
                            pw.SizedBox(height: 6),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.amber100,
                                borderRadius: pw.BorderRadius.circular(6),
                                border: pw.Border.all(color: PdfColors.amber700, width: 1.2),
                              ),
                              child: pw.Row(
                                mainAxisSize: pw.MainAxisSize.min,
                                children: [
                                  pw.Text('SECURITY PIN:  ', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                                  pw.Text(
                                    pinCode,
                                    style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900, letterSpacing: 2),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            _pdfInstructionRow('3', 'Tap Confirm to record attendance instantly.'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Anti-Fraud Policy notice
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.red200),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('!', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: pw.Text(
                        'HONESTY & ANTI-PROXY POLICY: Attendance is locked to 1 submission per physical device. Submissions outside classroom bounds or via forwarded photos will be flagged. Proxy attendance is a punishable academic offense.',
                        style: const pw.TextStyle(fontSize: 7.2, color: PdfColors.red900, lineSpacing: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Fallback Manual Roster
              pw.Text(
                'MANUAL ATTENDANCE ROSTER (For students with uncharged / unequipped phones)',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 5),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.7),
                columnWidths: {
                  0: const pw.FixedColumnWidth(28),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2.5),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _pdfHeaderCell('S/N'),
                      _pdfHeaderCell('Student Full Name'),
                      _pdfHeaderCell('Matric Number'),
                      _pdfHeaderCell('Student Signature'),
                    ],
                  ),
                  for (int i = 1; i <= 6; i++)
                    pw.TableRow(
                      children: [
                        _pdfBodyCell('$i', alignCenter: true),
                        _pdfBodyCell(''),
                        _pdfBodyCell(''),
                        _pdfBodyCell(''),
                      ],
                    ),
                ],
              ),
              pw.Spacer(),

              // Institutional Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by Lecturer Attendance System | Anti-Fraud Edition', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                  pw.Text('Lecturer Signature / Date: __________________________', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfInstructionRow(String step, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 14,
            height: 14,
            alignment: pw.Alignment.center,
            decoration: const pw.BoxDecoration(color: PdfColors.blue900, shape: pw.BoxShape.circle),
            child: pw.Text(step, style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _pdfBodyCell(String text, {bool alignCenter = false}) {
    return pw.Container(
      height: 22,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      alignment: alignCenter ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
      ),
    );
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
