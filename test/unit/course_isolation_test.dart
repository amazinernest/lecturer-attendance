import 'package:flutter_test/flutter_test.dart';
import 'package:lecturer_attendance/shared/models/course.dart';

void main() {
  group('Course & Lecturer Isolation Model Tests', () {
    test('Course status serializes and deserializes correctly', () {
      final course = Course(
        id: 'c1',
        lecturerId: 'lecturer_A',
        courseCode: 'GCE 202',
        courseTitle: 'Adolescence Psychology',
        department: 'Educational Foundations',
        level: '200 Level',
        semester: 'First Semester',
        academicSession: '2026/2027',
        expectedClasses: 15,
        status: CourseStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final map = course.toMap();
      expect(map['lecturerId'], equals('lecturer_A'));
      expect(map['status'], equals('active'));

      final restored = Course.fromMap(map);
      expect(restored.lecturerId, equals('lecturer_A'));
      expect(restored.status, equals(CourseStatus.active));
    });
  });
}
