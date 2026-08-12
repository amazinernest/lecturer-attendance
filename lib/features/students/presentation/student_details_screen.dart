import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/attendance_calculator.dart';
import '../../../shared/models/student.dart';
import '../../../shared/models/attendance_record.dart';
import '../../../shared/widgets/attendance_progress_ring.dart';

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
    final dateFormat = DateFormat('EEE, d MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder(
        future: Future.wait([
          db.getStudentsForCourse(courseId),
          db.getAllRecordsForCourse(courseId),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Student Details'),
                backgroundColor: AppColors.navyDeep,
                foregroundColor: Colors.white,
              ),
              body: const Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
            );
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

          // Student attendance map: sessionId → status
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

          final isAtRisk = stats.percentage < 75;
          final pct = stats.percentage;
          final avatarLetter =
              student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S';

          return CustomScrollView(
            slivers: [
              // ── Premium Collapsible Header ──────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.navyDeep,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 18, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0A1628), Color(0xFF1A3A6B)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                // Large avatar
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor:
                                      isAtRisk ? AppColors.error : AppColors.accent,
                                  child: Text(
                                    avatarLetter,
                                    style: AppTypography.displayLg.copyWith(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Name + matric
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: AppTypography.headlineLg.copyWith(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                            child: Text(
                                              student.matricNumber,
                                              style:
                                                  AppTypography.caption.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          if (isAtRisk) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.error
                                                    .withValues(alpha: 0.25),
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                              ),
                                              child: Text(
                                                '⚠️ At Risk',
                                                style: AppTypography.caption
                                                    .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Progress ring
                                AttendanceProgressRing(
                                  percentage: pct,
                                  size: 72,
                                  strokeWidth: 7,
                                  textColor: Colors.white,
                                  trackColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  ringColor: Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Body ───────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Stats grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.7,
                      children: [
                        _MiniStat(
                          title: 'ATTENDED',
                          value: '${stats.classesAttended}',
                          subtitle: 'of ${sessions.length} classes',
                          bg: AppColors.accentLight,
                          color: AppColors.accent,
                        ),
                        _MiniStat(
                          title: 'MISSED',
                          value: '${stats.classesMissed}',
                          subtitle: 'classes absent',
                          bg: isAtRisk
                              ? AppColors.errorBg
                              : AppColors.surfaceVariant,
                          color: isAtRisk ? AppColors.error : AppColors.textMuted,
                        ),
                        _MiniStat(
                          title: 'ATTENDANCE RATE',
                          value: stats.formattedPercentage,
                          subtitle: isAtRisk ? 'needs improvement' : 'on track',
                          bg: isAtRisk ? AppColors.errorBg : AppColors.successBg,
                          color: isAtRisk ? AppColors.error : AppColors.success,
                        ),
                        _MiniStat(
                          title: 'TOTAL SESSIONS',
                          value: '${sessions.length}',
                          subtitle: 'classes held',
                          bg: AppColors.warningBg,
                          color: AppColors.warning,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Attendance history header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attendance History',
                          style:
                              AppTypography.headlineMd.copyWith(fontSize: 16),
                        ),
                        Text(
                          '${sessions.length} sessions',
                          style: AppTypography.caption
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Session history list
                    if (sessions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Text('No classes recorded yet.',
                              style: AppTypography.bodyMd),
                        ),
                      )
                    else
                      ...sessions.map((sess) {
                        final status = studentRecordMap[sess.id] ??
                            AttendanceStatus.absent;
                        final isPresent = status == AttendanceStatus.present;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isPresent
                                ? AppColors.surface
                                : AppColors.errorBg.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isPresent
                                  ? AppColors.border
                                  : AppColors.error.withValues(alpha: 0.2),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isPresent
                                    ? AppColors.accentLight
                                    : AppColors.errorBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(
                                  isPresent
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  size: 20,
                                  color: isPresent
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                            title: Text(
                              'Class ${sess.classNumber} — ${sess.topic}',
                              style: AppTypography.titleSm.copyWith(
                                fontSize: 14,
                                color: isPresent
                                    ? AppColors.textPrimary
                                    : AppColors.error,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              dateFormat.format(sess.date),
                              style: AppTypography.caption,
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isPresent
                                    ? AppColors.successBg
                                    : AppColors.errorBg,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                isPresent ? 'Present' : 'Absent',
                                style: AppTypography.caption.copyWith(
                                  color: isPresent
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color bg;
  final Color color;

  const _MiniStat({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.bg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.statLg.copyWith(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: color.withValues(alpha: 0.65),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
