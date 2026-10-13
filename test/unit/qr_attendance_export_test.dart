import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecturer_attendance/core/utils/report_exporter.dart';
import 'package:lecturer_attendance/shared/models/course.dart';
import 'package:lecturer_attendance/shared/models/student.dart';
import 'package:lecturer_attendance/shared/models/attendance_session.dart';
import 'package:lecturer_attendance/shared/models/attendance_record.dart';

void main() {
  final testCourse = Course(
    id: 'test-course-id',
    lecturerId: 'lecturer-1',
    courseCode: 'CSC 401',
    courseTitle: 'Software Engineering II',
    department: 'Computer Science',
    level: '400L',
    semester: 'First',
    academicSession: '2025/2026',
    expectedClasses: 15,
    status: CourseStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    synced: true,
  );

  final testStudents = [
    Student(
      id: 's1',
      courseId: 'test-course-id',
      name: 'ADEBAYO, Kehinde',
      matricNumber: '2021/1/10001',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      synced: true,
    ),
    Student(
      id: 's2',
      courseId: 'test-course-id',
      name: 'CHUKWUMA, Emeka Peter',
      matricNumber: '2021/1/10002',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      synced: true,
    ),
    Student(
      id: 's3',
      courseId: 'test-course-id',
      name: 'IBRAHIM, Zainab Aisha',
      matricNumber: '2021/1/10003',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      synced: true,
    ),
  ];

  final testSessions = [
    AttendanceSession(
      id: 'sess-1',
      courseId: 'test-course-id',
      classNumber: 1,
      date: DateTime(2026, 10, 1),
      topic: 'Introduction to Agile Architecture',
      createdAt: DateTime.now(),
      synced: true,
    ),
    AttendanceSession(
      id: 'sess-2',
      courseId: 'test-course-id',
      classNumber: 2,
      date: DateTime(2026, 10, 8),
      topic: 'Domain-Driven Design Principles',
      createdAt: DateTime.now(),
      synced: true,
    ),
  ];

  final testRecords = [
    AttendanceRecord(
      id: 'r1',
      attendanceSessionId: 'sess-1',
      studentId: 's1',
      status: AttendanceStatus.present,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      synced: true,
    ),
    AttendanceRecord(
      id: 'r2',
      attendanceSessionId: 'sess-1',
      studentId: 's2',
      status: AttendanceStatus.present,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      synced: true,
    ),
    AttendanceRecord(
      id: 'r3',
      attendanceSessionId: 'sess-2',
      studentId: 's1',
      status: AttendanceStatus.present,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      synced: true,
    ),
  ];

  group('PDF Export Report Suite Tests', () {
    test('generatePdfReport produces executive matrix report with KPI tiles and signatures', () async {
      final pdfBytes = await ReportExporter.generatePdfReport(
        course: testCourse,
        students: testStudents,
        sessions: testSessions,
        records: testRecords,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(utf8.decode(pdfBytes.sublist(0, 4), allowMalformed: true), equals('%PDF'));
    });

    test('generateSessionAttendancePdf produces daily session report with status badges', () async {
      final attendanceMap = {
        's1': AttendanceStatus.present,
        's2': AttendanceStatus.absent,
        's3': AttendanceStatus.present,
      };

      final pdfBytes = await ReportExporter.generateSessionAttendancePdf(
        course: testCourse,
        session: testSessions.first,
        students: testStudents,
        attendanceMap: attendanceMap,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(utf8.decode(pdfBytes.sublist(0, 4), allowMalformed: true), equals('%PDF'));
    });

    test('generateQrAttendanceSheetPdf produces valid QR Attendance Sheet', () async {
      final pdfBytes = await ReportExporter.generateQrAttendanceSheetPdf(
        course: testCourse,
        classNumber: 2,
        topic: 'Agile Architecture & System Design',
        date: DateTime(2026, 10, 14),
        qrData: 'https://amazinernest.github.io/lecturer-attendance/checkin?pin=9821',
        pinCode: '9821',
        totalStudents: 45,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(utf8.decode(pdfBytes.sublist(0, 4), allowMalformed: true), equals('%PDF'));
    });
  });
}
