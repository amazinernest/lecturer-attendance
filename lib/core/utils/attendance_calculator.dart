class StudentAttendanceStats {
  final int classesAttended;
  final int classesMissed;
  final int totalClassesHeld;
  final double percentage;

  const StudentAttendanceStats({
    required this.classesAttended,
    required this.classesMissed,
    required this.totalClassesHeld,
    required this.percentage,
  });

  String get formattedPercentage => '${percentage.toStringAsFixed(1)}%';
}

class CourseAttendanceSummary {
  final int totalStudents;
  final int classesHeld;
  final double averageAttendancePercentage;
  final int studentsWithHundredPercent;
  final int studentsBelow75Percent;
  final Map<String, int> distribution;

  const CourseAttendanceSummary({
    required this.totalStudents,
    required this.classesHeld,
    required this.averageAttendancePercentage,
    required this.studentsWithHundredPercent,
    required this.studentsBelow75Percent,
    required this.distribution,
  });
}

class AttendanceCalculator {
  AttendanceCalculator._();

  /// Calculates individual student percentage according to section 16 & 17
  static double calculatePercentage(int classesAttended, int totalClassesHeld) {
    if (totalClassesHeld <= 0) return 0.0;
    final pct = (classesAttended / totalClassesHeld) * 100.0;
    return double.parse(pct.toStringAsFixed(1));
  }

  /// Calculates individual student stats given total classes held and list of present session IDs
  static StudentAttendanceStats calculateStudentStats({
    required int totalClassesHeld,
    required int classesAttended,
  }) {
    final missed = (totalClassesHeld - classesAttended).clamp(0, totalClassesHeld);
    final pct = calculatePercentage(classesAttended, totalClassesHeld);
    return StudentAttendanceStats(
      classesAttended: classesAttended,
      classesMissed: missed,
      totalClassesHeld: totalClassesHeld,
      percentage: pct,
    );
  }

  /// Calculates summary stats across all students in a course
  static CourseAttendanceSummary calculateCourseSummary({
    required int classesHeld,
    required List<StudentAttendanceStats> studentStatsList,
  }) {
    if (studentStatsList.isEmpty) {
      return const CourseAttendanceSummary(
        totalStudents: 0,
        classesHeld: 0,
        averageAttendancePercentage: 0.0,
        studentsWithHundredPercent: 0,
        studentsBelow75Percent: 0,
        distribution: {
          '90-100%': 0,
          '75-89%': 0,
          '50-74%': 0,
          '<50%': 0,
        },
      );
    }

    final totalStudents = studentStatsList.length;
    double totalPctSum = 0.0;
    int hundredCount = 0;
    int below75Count = 0;

    int range90_100 = 0;
    int range75_89 = 0;
    int range50_74 = 0;
    int rangeBelow50 = 0;

    for (final stats in studentStatsList) {
      final p = stats.percentage;
      totalPctSum += p;

      if (p >= 100.0) hundredCount++;
      if (p < 75.0) below75Count++;

      if (p >= 90.0) {
        range90_100++;
      } else if (p >= 75.0) {
        range75_89++;
      } else if (p >= 50.0) {
        range50_74++;
      } else {
        rangeBelow50++;
      }
    }

    final avgPct = double.parse((totalPctSum / totalStudents).toStringAsFixed(1));

    return CourseAttendanceSummary(
      totalStudents: totalStudents,
      classesHeld: classesHeld,
      averageAttendancePercentage: avgPct,
      studentsWithHundredPercent: hundredCount,
      studentsBelow75Percent: below75Count,
      distribution: {
        '90-100%': range90_100,
        '75-89%': range75_89,
        '50-74%': range50_74,
        '<50%': rangeBelow50,
      },
    );
  }
}
