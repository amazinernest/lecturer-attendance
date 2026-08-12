import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/attendance_calculator.dart';
import '../../../core/utils/report_exporter.dart';
import '../../../shared/models/student.dart';
import '../../../shared/models/attendance_session.dart';
import '../../../shared/models/attendance_record.dart';
import '../../../shared/widgets/attendance_progress_ring.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _selectedCourseId;
  bool _isGeneratingPdf = false;
  bool _isGeneratingExcel = false;

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesStreamProvider);
    final db = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Reports',
                          style: AppTypography.displayLg.copyWith(fontSize: 24),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.analytics_outlined,
                            size: 20, color: AppColors.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generate attendance reports for your courses.',
                    style: AppTypography.bodyMd,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: coursesAsync.when(
                data: (courses) {
                  if (courses.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: AppColors.warningBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bar_chart_outlined,
                                  size: 36, color: AppColors.warning),
                            ),
                            const SizedBox(height: 20),
                            Text('No courses available',
                                style: AppTypography.headlineMd.copyWith(
                                    fontSize: 18)),
                            const SizedBox(height: 8),
                            Text(
                              'Add courses and record attendance to generate reports.',
                              style: AppTypography.bodyMd,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  _selectedCourseId ??= courses.first.id;
                  final selectedCourse = courses.firstWhere(
                    (c) => c.id == _selectedCourseId,
                    orElse: () => courses.first,
                  );

                  return FutureBuilder(
                    future: Future.wait([
                      db.getStudentsForCourse(selectedCourse.id),
                      db.getSessionsForCourse(selectedCourse.id),
                      db.getAllRecordsForCourse(selectedCourse.id),
                    ]),
                    builder: (context, snapshot) {
                      final students = snapshot.hasData
                          ? (snapshot.data![0] as List<Student>)
                          : <Student>[];
                      final sessions = snapshot.hasData
                          ? (snapshot.data![1] as List<AttendanceSession>)
                          : <AttendanceSession>[];
                      final records = snapshot.hasData
                          ? (snapshot.data![2] as List<AttendanceRecord>)
                          : <AttendanceRecord>[];

                      // Build record map
                      final recordMap = <String, Map<String, bool>>{};
                      for (final r in records) {
                        recordMap.putIfAbsent(r.attendanceSessionId,
                            () => {})[r.studentId] =
                            (r.status == AttendanceStatus.present);
                      }

                      // Student stats
                      final studentStatsList = students.map((s) {
                        int attended = 0;
                        for (final sess in sessions) {
                          if (recordMap[sess.id]?[s.id] == true) attended++;
                        }
                        return AttendanceCalculator.calculateStudentStats(
                          totalClassesHeld: sessions.length,
                          classesAttended: attended,
                        );
                      }).toList();

                      final summary =
                          AttendanceCalculator.calculateCourseSummary(
                        classesHeld: sessions.length,
                        studentStatsList: studentStatsList,
                      );

                      final avgPct = summary.averageAttendancePercentage;
                      final atRiskCount = summary.studentsBelow75Percent;
                      final onTrackCount = students.length - atRiskCount;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Course Selector ────────────────────────
                            Text(
                              'Select Course',
                              style: AppTypography.titleSm.copyWith(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedCourseId,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                                items: courses.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c.id,
                                    child: Text(
                                        '${c.courseCode} — ${c.courseTitle}',
                                        overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCourseId = val);
                                  }
                                },
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Featured Attendance Card ────────────────
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF0A1628), Color(0xFF1A3A6B)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AVG ATTENDANCE',
                                          style: AppTypography.caption.copyWith(
                                            color: Colors.white
                                                .withValues(alpha: 0.6),
                                            fontSize: 10,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${avgPct.toStringAsFixed(1)}%',
                                          style: AppTypography.statXL.copyWith(
                                            color: Colors.white,
                                            fontSize: 40,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          selectedCourse.courseTitle,
                                          style: AppTypography.bodyMd.copyWith(
                                            color: Colors.white
                                                .withValues(alpha: 0.6),
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  AttendanceProgressRing(
                                    percentage: avgPct,
                                    size: 80,
                                    strokeWidth: 8,
                                    textColor: Colors.white,
                                    trackColor:
                                        Colors.white.withValues(alpha: 0.2),
                                    ringColor: Colors.white,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // ── Stats Row ──────────────────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: _ReportStatBox(
                                    title: 'Students',
                                    value: '${students.length}',
                                    icon: Icons.people_alt_outlined,
                                    bg: AppColors.accentLight,
                                    color: AppColors.navyMid,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ReportStatBox(
                                    title: 'Classes Held',
                                    value: '${sessions.length}',
                                    icon: Icons.event_note_outlined,
                                    bg: AppColors.warningBg,
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ReportStatBox(
                                    title: 'At Risk',
                                    value: '$atRiskCount',
                                    icon: Icons.warning_amber_rounded,
                                    bg: AppColors.errorBg,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Distribution bar
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Attendance Distribution',
                                      style: AppTypography.headlineMd
                                          .copyWith(fontSize: 14)),
                                  const SizedBox(height: 12),
                                  _DistBar(
                                    label: 'On Track (≥75%)',
                                    count: onTrackCount,
                                    total: students.length,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(height: 10),
                                  _DistBar(
                                    label: 'At Risk (<75%)',
                                    count: atRiskCount,
                                    total: students.length,
                                    color: AppColors.error,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Export Buttons ──────────────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isGeneratingPdf
                                        ? null
                                        : () async {
                                            setState(() =>
                                                _isGeneratingPdf = true);
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            try {
                                              final pdfBytes = await ReportExporter
                                                  .generatePdfReport(
                                                course: selectedCourse,
                                                students: students,
                                                sessions: sessions,
                                                records: records,
                                              );
                                              StorageService().uploadReportDocument(
                                                pdfBytes,
                                                '${selectedCourse.courseCode}_Attendance_Report.pdf',
                                              );
                                              await ReportExporter.printOrSharePdf(
                                                pdfBytes: pdfBytes,
                                                filename:
                                                    '${selectedCourse.courseCode}_Attendance_Report',
                                              );
                                            } catch (e) {
                                              if (mounted) {
                                                messenger.showSnackBar(SnackBar(
                                                    content: Text(
                                                        'PDF export failed: $e'),
                                                    backgroundColor:
                                                        AppColors.error));
                                              }
                                            } finally {
                                              if (mounted) {
                                                setState(() =>
                                                    _isGeneratingPdf = false);
                                              }
                                            }
                                          },
                                    icon: _isGeneratingPdf
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Icon(
                                            Icons.picture_as_pdf_outlined,
                                            size: 18),
                                    label: Text(_isGeneratingPdf
                                        ? 'Generating…'
                                        : 'Export PDF'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isGeneratingExcel
                                        ? null
                                        : () async {
                                            setState(() =>
                                                _isGeneratingExcel = true);
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            try {
                                              final excelBytes =
                                                  ReportExporter
                                                      .generateExcelReport(
                                                course: selectedCourse,
                                                students: students,
                                                sessions: sessions,
                                                records: records,
                                              );
                                              StorageService().uploadReportDocument(
                                                excelBytes,
                                                '${selectedCourse.courseCode}_Attendance_Sheet.xlsx',
                                              );
                                              await ReportExporter.shareFile(
                                                bytes: excelBytes,
                                                filename:
                                                    '${selectedCourse.courseCode}_Attendance_Sheet.xlsx',
                                                mimeType:
                                                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                              );
                                            } catch (e) {
                                              if (mounted) {
                                                messenger.showSnackBar(SnackBar(
                                                    content: Text(
                                                        'Excel export failed: $e'),
                                                    backgroundColor:
                                                        AppColors.error));
                                              }
                                            } finally {
                                              if (mounted) {
                                                setState(() =>
                                                    _isGeneratingExcel = false);
                                              }
                                            }
                                          },
                                    icon: _isGeneratingExcel
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.accent))
                                        : const Icon(Icons.table_chart_outlined,
                                            size: 18),
                                    label: Text(_isGeneratingExcel
                                        ? 'Generating…'
                                        : 'Export Excel'),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ── Student Table ───────────────────────────
                            Text(
                              'Student Breakdown',
                              style: AppTypography.headlineMd.copyWith(
                                  fontSize: 16),
                            ),
                            const SizedBox(height: 12),

                            if (students.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Center(
                                  child: Text('No students enrolled.',
                                      style: AppTypography.bodyMd),
                                ),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: students.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final s = students[index];
                                    final stats = studentStatsList[index];
                                    final isGood = stats.percentage >= 75;

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 6),
                                      leading: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: isGood
                                            ? AppColors.successBg
                                            : AppColors.errorBg,
                                        child: Text(
                                          '${index + 1}',
                                          style:
                                              AppTypography.caption.copyWith(
                                            color: isGood
                                                ? AppColors.success
                                                : AppColors.error,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      title: Text(s.name,
                                          style: AppTypography.titleSm
                                              .copyWith(fontSize: 14)),
                                      subtitle: Text(s.matricNumber,
                                          style: AppTypography.caption),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${stats.classesAttended}/${sessions.length}',
                                            style: AppTypography.titleSm
                                                .copyWith(fontSize: 13),
                                          ),
                                          Text(
                                            stats.formattedPercentage,
                                            style: AppTypography.caption
                                                .copyWith(
                                              color: isGood
                                                  ? AppColors.success
                                                  : AppColors.error,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accent)),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _ReportStatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color bg;
  final Color color;

  const _ReportStatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.bg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.statLg.copyWith(
                color: color, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(
            title,
            style: AppTypography.caption.copyWith(color: color.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _DistBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _DistBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodyMd.copyWith(fontSize: 13)),
            Text('$count students',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
