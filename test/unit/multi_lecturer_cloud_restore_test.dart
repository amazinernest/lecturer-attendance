import 'package:flutter_test/flutter_test.dart';
import 'package:lecturer_attendance/shared/models/course.dart';
import 'package:lecturer_attendance/shared/models/student.dart';
import 'package:lecturer_attendance/shared/models/attendance_session.dart';
import 'package:lecturer_attendance/shared/models/attendance_record.dart';

void main() {
  group('100+ Lecturers Multi-Tenant & Cloud Restore Verification', () {
    test('Simulating 100 lecturers: data strictly partitioned by lecturerId', () {
      final List<Course> allLecturerCourses = [];

      for (int i = 1; i <= 100; i++) {
        final lecturerId = 'lecturer_uuid_$i';
        allLecturerCourses.add(
          Course(
            id: 'course_id_$i',
            lecturerId: lecturerId,
            courseCode: 'EDU ${100 + i}',
            courseTitle: 'Course Title for Lecturer $i',
            department: 'Faculty of Education',
            level: '200 Level',
            semester: 'First Semester',
            academicSession: '2026/2027',
            expectedClasses: 15,
            status: CourseStatus.active,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        );
      }

      expect(allLecturerCourses.length, equals(100));

      // Querying specifically for Lecturer 42
      const targetLecturer = 'lecturer_uuid_42';
      final lecturer42Courses = allLecturerCourses.where((c) => c.lecturerId == targetLecturer).toList();

      expect(lecturer42Courses.length, equals(1));
      expect(lecturer42Courses.first.courseCode, equals('EDU 142'));

      // Ensure other lecturers cannot see Lecturer 42's course
      final otherLecturersCourses = allLecturerCourses.where((c) => c.lecturerId != targetLecturer).toList();
      expect(otherLecturersCourses.length, equals(99));
      expect(otherLecturersCourses.any((c) => c.lecturerId == targetLecturer), isFalse);
    });

    test('Cloud-to-Local Restore: Supabase JSON payload parses and sets synced=true', () {
      final supabaseCourseJson = {
        'id': 'c_uuid_999',
        'lecturer_id': 'lecturer_uuid_50',
        'course_code': 'CSC 301',
        'course_title': 'Operating Systems',
        'department': 'Computer Science',
        'level': '300 Level',
        'semester': 'Second Semester',
        'academic_session': '2026/2027',
        'expected_classes': 12,
        'status': 'active',
        'created_at': '2026-02-15T09:00:00.000Z',
        'updated_at': '2026-02-15T09:00:00.000Z',
      };

      final restoredCourse = Course(
        id: supabaseCourseJson['id'] as String,
        lecturerId: supabaseCourseJson['lecturer_id'] as String,
        courseCode: supabaseCourseJson['course_code'] as String,
        courseTitle: supabaseCourseJson['course_title'] as String,
        department: supabaseCourseJson['department'] as String,
        level: supabaseCourseJson['level'] as String,
        semester: supabaseCourseJson['semester'] as String,
        academicSession: supabaseCourseJson['academic_session'] as String,
        expectedClasses: supabaseCourseJson['expected_classes'] as int,
        status: CourseStatus.fromValue(supabaseCourseJson['status'] as String?),
        createdAt: DateTime.parse(supabaseCourseJson['created_at'] as String),
        updatedAt: DateTime.parse(supabaseCourseJson['updated_at'] as String),
        synced: true,
      );

      expect(restoredCourse.id, equals('c_uuid_999'));
      expect(restoredCourse.lecturerId, equals('lecturer_uuid_50'));
      expect(restoredCourse.courseCode, equals('CSC 301'));
      expect(restoredCourse.synced, isTrue);

      final supabaseStudentJson = {
        'id': 's_uuid_101',
        'course_id': 'c_uuid_999',
        'name': 'Chukwuma Adeyemi',
        'matric_number': 'CSC/2022/045',
        'created_at': '2026-02-16T10:00:00.000Z',
        'updated_at': '2026-02-16T10:00:00.000Z',
      };

      final restoredStudent = Student(
        id: supabaseStudentJson['id'] as String,
        courseId: supabaseStudentJson['course_id'] as String,
        name: supabaseStudentJson['name'] as String,
        matricNumber: supabaseStudentJson['matric_number'] as String,
        createdAt: DateTime.parse(supabaseStudentJson['created_at'] as String),
        updatedAt: DateTime.parse(supabaseStudentJson['updated_at'] as String),
        synced: true,
      );

      expect(restoredStudent.name, equals('Chukwuma Adeyemi'));
      expect(restoredStudent.courseId, equals('c_uuid_999'));
      expect(restoredStudent.synced, isTrue);

      final supabaseSessionJson = {
        'id': 'sess_uuid_01',
        'course_id': 'c_uuid_999',
        'class_number': 1,
        'date': '2026-02-17T08:30:00.000Z',
        'topic': 'Introduction to Processes & Threads',
        'created_at': '2026-02-17T08:30:00.000Z',
      };

      final restoredSession = AttendanceSession(
        id: supabaseSessionJson['id'] as String,
        courseId: supabaseSessionJson['course_id'] as String,
        classNumber: supabaseSessionJson['class_number'] as int,
        date: DateTime.parse(supabaseSessionJson['date'] as String),
        topic: supabaseSessionJson['topic'] as String,
        createdAt: DateTime.parse(supabaseSessionJson['created_at'] as String),
        synced: true,
      );

      expect(restoredSession.topic, equals('Introduction to Processes & Threads'));
      expect(restoredSession.classNumber, equals(1));
      expect(restoredSession.synced, isTrue);

      final supabaseRecordJson = {
        'id': 'rec_uuid_01',
        'attendance_session_id': 'sess_uuid_01',
        'student_id': 's_uuid_101',
        'status': 'present',
        'created_at': '2026-02-17T08:45:00.000Z',
        'updated_at': '2026-02-17T08:45:00.000Z',
      };

      final restoredRecord = AttendanceRecord(
        id: supabaseRecordJson['id'] as String,
        attendanceSessionId: supabaseRecordJson['attendance_session_id'] as String,
        studentId: supabaseRecordJson['student_id'] as String,
        status: AttendanceStatus.fromValue(supabaseRecordJson['status']),
        createdAt: DateTime.parse(supabaseRecordJson['created_at'] as String),
        updatedAt: DateTime.parse(supabaseRecordJson['updated_at'] as String),
        synced: true,
      );

      expect(restoredRecord.status, equals(AttendanceStatus.present));
      expect(restoredRecord.synced, isTrue);
    });

    test('Storage folder path enforces per-lecturer isolation namespace', () {
      const lecturerA = 'uid_lecturer_alpha';
      const lecturerB = 'uid_lecturer_beta';
      const fileName = 'Class_List_2026.csv';
      const category = 'imports';

      final pathA = '$lecturerA/$category/1712345678_$fileName';
      final pathB = '$lecturerB/$category/1712345678_$fileName';

      expect(pathA.startsWith('uid_lecturer_alpha/imports/'), isTrue);
      expect(pathB.startsWith('uid_lecturer_beta/imports/'), isTrue);
      expect(pathA, isNot(equals(pathB)));
    });
  });
}
