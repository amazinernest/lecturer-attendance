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
      appBar: AppBar(
        title: Text('Attendance Reports', style: AppTypography.headlineLg.copyWith(fontSize: 20)),
      ),
      body: coursesAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return const Center(child: Text('No courses available to generate reports for.'));
          }

          _selectedCourseId ??= courses.first.id;
          final selectedCourse = courses.firstWhere(
            (c) => c.id == _selectedCourseId,
            orElse: () => courses.first,
          );

          return Column(
            children: [
              // Course Selector Header
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Course', style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCourseId,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: courses.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.id,
                          child: Text('${c.courseCode} — ${c.courseTitle}', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCourseId = val);
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Report Content & Table
              Expanded(
                child: FutureBuilder(
                  future: Future.wait([
                    db.getStudentsForCourse(selectedCourse.id),
                    db.getSessionsForCourse(selectedCourse.id),
                    db.getAllRecordsForCourse(selectedCourse.id),
                  ]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer));
                    }

                    final students = snapshot.data![0] as List<Student>;
                    final sessions = snapshot.data![1] as List<AttendanceSession>;
                    final records = snapshot.data![2] as List<AttendanceRecord>;

                    // Record Map: sessionId -> studentId -> isPresent
                    final recordMap = <String, Map<String, bool>>{};
                    for (final r in records) {
                      recordMap.putIfAbsent(r.attendanceSessionId, () => {})[r.studentId] = (r.status == AttendanceStatus.present);
                    }

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

                    final summary = AttendanceCalculator.calculateCourseSummary(
                      classesHeld: sessions.length,
                      studentStatsList: studentStatsList,
                    );

                    return Column(
                      children: [
                        // Summary Bar & Export Action Buttons
                        Container(
                          color: AppColors.surface,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _ReportStat(title: 'Students', value: '${students.length}'),
                                  _ReportStat(title: 'Classes Held', value: '${sessions.length}'),
                                  _ReportStat(
                                    title: 'Avg Attendance',
                                    value: '${summary.averageAttendancePercentage.toStringAsFixed(0)}%',
                                    color: summary.averageAttendancePercentage >= 75 ? AppColors.presentGreen : AppColors.absentRed,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  // Export PDF Button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isGeneratingPdf
                                          ? null
                                          : () async {
                                              setState(() => _isGeneratingPdf = true);
                                              final messenger = ScaffoldMessenger.of(context);
                                              try {
                                                final pdfBytes = await ReportExporter.generatePdfReport(
                                                  course: selectedCourse,
                                                  students: students,
                                                  sessions: sessions,
                                                  records: records,
                                                );

                                                // Upload generated report backup to Supabase Storage bucket: lecturers-attendance-files
                                                StorageService().uploadReportDocument(
                                                  pdfBytes,
                                                  '${selectedCourse.courseCode}_Attendance_Report.pdf',
                                                );

                                                await ReportExporter.printOrSharePdf(
                                                  pdfBytes: pdfBytes,
                                                  filename: '${selectedCourse.courseCode}_Attendance_Report',
                                                );
                                              } catch (e) {
                                                if (mounted) {
                                                  messenger.showSnackBar(
                                                    SnackBar(content: Text('PDF export failed: $e')),
                                                  );
                                                }
                                              } finally {
                                                if (mounted) setState(() => _isGeneratingPdf = false);
                                              }
                                            },
                                      icon: _isGeneratingPdf
                                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                                      label: Text(_isGeneratingPdf ? 'Generating...' : 'Export PDF'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Export Excel Button
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isGeneratingExcel
                                          ? null
                                          : () async {
                                              setState(() => _isGeneratingExcel = true);
                                              final messenger = ScaffoldMessenger.of(context);
                                              try {
                                                final excelBytes = ReportExporter.generateExcelReport(
                                                  course: selectedCourse,
                                                  students: students,
                                                  sessions: sessions,
                                                  records: records,
                                                );

                                                // Upload generated Excel report backup to Supabase Storage bucket: lecturers-attendance-files
                                                StorageService().uploadReportDocument(
                                                  excelBytes,
                                                  '${selectedCourse.courseCode}_Attendance_Sheet.xlsx',
                                                );

                                                await ReportExporter.shareFile(
                                                  bytes: excelBytes,
                                                  filename: '${selectedCourse.courseCode}_Attendance_Sheet.xlsx',
                                                  mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                                );
                                              } catch (e) {
                                                if (mounted) {
                                                  messenger.showSnackBar(
                                                    SnackBar(content: Text('Excel export failed: $e')),
                                                  );
                                                }
                                              } finally {
                                                if (mounted) setState(() => _isGeneratingExcel = false);
                                              }
                                            },
                                      icon: _isGeneratingExcel
                                          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryContainer))
                                          : const Icon(Icons.table_view_outlined, size: 18),
                                      label: Text(_isGeneratingExcel ? 'Generating...' : 'Export Excel'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Student Report Table List
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: students.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final s = students[index];
                              final stats = studentStatsList[index];

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.1),
                                  child: Text('${index + 1}', style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700)),
                                ),
                                title: Text(s.name, style: AppTypography.titleMd.copyWith(fontSize: 15)),
                                subtitle: Text(s.matricNumber, style: AppTypography.labelMd),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${stats.classesAttended} / ${sessions.length}',
                                      style: AppTypography.titleMd.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      stats.formattedPercentage,
                                      style: AppTypography.labelMd.copyWith(
                                        color: stats.percentage >= 75 ? AppColors.presentGreen : AppColors.absentRed,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;

  const _ReportStat({
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
