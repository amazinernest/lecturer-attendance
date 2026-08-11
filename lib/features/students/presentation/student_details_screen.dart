import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/attendance_calculator.dart';
import '../../../shared/models/student.dart';
import '../../../shared/models/attendance_record.dart';

class StudentDetailsScreen extends ConsumerWidget {
  final String courseId;
  final String studentId;

  const StudentDetailsScreen({
    super.key,
    required this.courseId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final sessionsAsync = ref.watch(sessionsStreamProvider(courseId));
    final dateFormat = DateFormat('dd MMMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Details'),
      ),
      body: FutureBuilder(
        future: Future.wait([
          db.getStudentsForCourse(courseId),
          db.getAllRecordsForCourse(courseId),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer));
          }

          final students = snapshot.data![0] as List<Student>;
          final allRecords = snapshot.data![1] as List<AttendanceRecord>;
          final sessions = sessionsAsync.value ?? [];

          final student = students.firstWhere(
            (s) => s.id == studentId,
            orElse: () => Student(
              id: studentId,
              courseId: courseId,
              name: 'Unknown Student',
              matricNumber: 'N/A',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          // Student attendance map: sessionId -> status
          final studentRecordMap = <String, AttendanceStatus>{};
          for (final r in allRecords.where((r) => r.studentId == studentId)) {
            studentRecordMap[r.attendanceSessionId] = r.status;
          }

          int attendedCount = 0;
          for (final sess in sessions) {
            if (studentRecordMap[sess.id] == AttendanceStatus.present) {
              attendedCount++;
            }
          }

          final stats = AttendanceCalculator.calculateStudentStats(
            totalClassesHeld: sessions.length,
            classesAttended: attendedCount,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                          style: AppTypography.displayLg.copyWith(fontSize: 22, color: AppColors.onPrimary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: AppTypography.headlineLg.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Matric No: ${student.matricNumber}',
                              style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Attendance Overview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(title: 'Classes Attended', value: '${stats.classesAttended} / ${sessions.length}'),
                      const SizedBox(height: 30, child: VerticalDivider()),
                      _StatColumn(title: 'Missed', value: '${stats.classesMissed}'),
                      const SizedBox(height: 30, child: VerticalDivider()),
                      _StatColumn(
                        title: 'Percentage',
                        value: stats.formattedPercentage,
                        color: stats.percentage >= 75 ? AppColors.presentGreen : AppColors.absentRed,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Attendance History',
                style: AppTypography.titleMd.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 12),

              if (sessions.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No classes have been held yet.',
                        style: AppTypography.labelMd,
                      ),
                    ),
                  ),
                )
              else
                ...sessions.map((sess) {
                  final status = studentRecordMap[sess.id] ?? AttendanceStatus.absent;
                  final isPresent = status == AttendanceStatus.present;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        'Class ${sess.classNumber} — ${sess.topic}',
                        style: AppTypography.titleMd.copyWith(fontSize: 15),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(dateFormat.format(sess.date), style: AppTypography.labelMd),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPresent ? AppColors.presentBg : AppColors.absentBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPresent ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: isPresent ? AppColors.presentGreen : AppColors.absentRed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPresent ? 'Present' : 'Absent',
                              style: AppTypography.labelMd.copyWith(
                                color: isPresent ? AppColors.presentGreen : AppColors.absentRed,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;

  const _StatColumn({
    required this.title,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.statLg.copyWith(fontSize: 20, color: color ?? AppColors.primaryContainer)),
        const SizedBox(height: 2),
        Text(title, style: AppTypography.labelMd.copyWith(fontSize: 12)),
      ],
    );
  }
}
