import 'package:flutter_test/flutter_test.dart';
import 'package:lecturer_attendance/core/utils/attendance_calculator.dart';

void main() {
  group('AttendanceCalculator Tests', () {
    test('Calculate percentage 12 out of 15 should equal 80%', () {
      final pct = AttendanceCalculator.calculatePercentage(12, 15);
      expect(pct, equals(80.0));
    });

    test('Zero total classes held should return 0% without division by zero', () {
      final pct = AttendanceCalculator.calculatePercentage(0, 0);
      expect(pct, equals(0.0));
    });

    test('Calculate stats for 7 attended out of 8 classes held (denominator rule)', () {
      final stats = AttendanceCalculator.calculateStudentStats(
        totalClassesHeld: 8,
        classesAttended: 7,
      );

      expect(stats.classesAttended, equals(7));
      expect(stats.classesMissed, equals(1));
      expect(stats.totalClassesHeld, equals(8));
      expect(stats.percentage, equals(87.5));
      expect(stats.formattedPercentage, equals('87.5%'));
    });

    test('Course summary calculation correctly distributes percentages into ranges', () {
      final studentStats = [
        const StudentAttendanceStats(classesAttended: 10, classesMissed: 0, totalClassesHeld: 10, percentage: 100.0),
        const StudentAttendanceStats(classesAttended: 8, classesMissed: 2, totalClassesHeld: 10, percentage: 80.0),
        const StudentAttendanceStats(classesAttended: 6, classesMissed: 4, totalClassesHeld: 10, percentage: 60.0),
        const StudentAttendanceStats(classesAttended: 3, classesMissed: 7, totalClassesHeld: 10, percentage: 30.0),
      ];

      final summary = AttendanceCalculator.calculateCourseSummary(
        classesHeld: 10,
        studentStatsList: studentStats,
      );

      expect(summary.totalStudents, equals(4));
      expect(summary.classesHeld, equals(10));
      expect(summary.averageAttendancePercentage, equals(67.5));
      expect(summary.studentsWithHundredPercent, equals(1));
      expect(summary.studentsBelow75Percent, equals(2));
      expect(summary.distribution['90-100%'], equals(1));
      expect(summary.distribution['75-89%'], equals(1));
      expect(summary.distribution['50-74%'], equals(1));
      expect(summary.distribution['<50%'], equals(1));
    });
  });
}
