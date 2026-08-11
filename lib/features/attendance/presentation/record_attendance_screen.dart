import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../shared/models/course.dart';
import '../../../shared/models/student.dart';
import '../../../shared/models/attendance_session.dart';
import '../../../shared/models/attendance_record.dart';
import '../../../shared/widgets/attendance_toggle.dart';

class RecordAttendanceScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String? existingSessionId;

  const RecordAttendanceScreen({
    super.key,
    required this.courseId,
    this.existingSessionId,
  });

  @override
  ConsumerState<RecordAttendanceScreen> createState() => _RecordAttendanceScreenState();
}

class _RecordAttendanceScreenState extends ConsumerState<RecordAttendanceScreen> {
  final _uuid = const Uuid();
  late TextEditingController _topicController;
  late TextEditingController _classNumberController;
  DateTime _sessionDate = DateTime.now();

  Map<String, AttendanceStatus> _attendanceStatusMap = {};
  bool _isLoading = true;
  bool _isSaving = false;
  List<Student> _students = [];
  Course? _course;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: 'Lecture Review');
    _classNumberController = TextEditingController(text: '1');
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final db = ref.read(databaseProvider);
    final course = await db.getCourseById(widget.courseId);
    final students = await db.getStudentsForCourse(widget.courseId);
    final existingSessions = await db.getSessionsForCourse(widget.courseId);

    final statusMap = <String, AttendanceStatus>{};

    if (widget.existingSessionId != null) {
      final existingSession = existingSessions.firstWhere((s) => s.id == widget.existingSessionId);
      _topicController.text = existingSession.topic;
      _classNumberController.text = '${existingSession.classNumber}';
      _sessionDate = existingSession.date;

      final existingRecords = await db.getRecordsForSession(widget.existingSessionId!);
      for (final r in existingRecords) {
        statusMap[r.studentId] = r.status;
      }
    } else {
      _classNumberController.text = '${existingSessions.length + 1}';
      for (final s in students) {
        statusMap[s.id] = AttendanceStatus.present;
      }
    }

    // Default missing to present
    for (final s in students) {
      statusMap.putIfAbsent(s.id, () => AttendanceStatus.present);
    }

    if (mounted) {
      setState(() {
        _course = course;
        _students = students;
        _attendanceStatusMap = statusMap;
        _isLoading = false;
      });
    }
  }

  void _markAllPresent() {
    setState(() {
      for (final s in _students) {
        _attendanceStatusMap[s.id] = AttendanceStatus.present;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All students marked as Present'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.presentGreen,
      ),
    );
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students in this course to record attendance for.')),
      );
      return;
    }

    final classNum = int.tryParse(_classNumberController.text.trim());
    if (classNum == null || classNum <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid class number.')),
      );
      return;
    }

    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a class topic.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      final sessionId = widget.existingSessionId ?? _uuid.v4();

      final session = AttendanceSession(
        id: sessionId,
        courseId: widget.courseId,
        classNumber: classNum,
        date: _sessionDate,
        topic: topic,
        createdAt: now,
        synced: false,
      );

      final records = _students.map((s) {
        return AttendanceRecord(
          id: _uuid.v4(),
          attendanceSessionId: sessionId,
          studentId: s.id,
          status: _attendanceStatusMap[s.id] ?? AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
          synced: false,
        );
      }).toList();

      await db.saveAttendanceSessionTransaction(
        session: session,
        recordsList: records,
      );

      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(syncServiceProvider).syncNow(lecturerId: user.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance saved successfully. ${_students.length} students processed.'),
            backgroundColor: AppColors.presentGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save attendance: $e'), backgroundColor: AppColors.absentRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Record Attendance')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer)),
      );
    }

    final dateFormat = DateFormat('dd MMMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_course != null ? '${_course!.courseCode} — Record' : 'Record Attendance'),
        actions: [
          TextButton.icon(
            onPressed: _markAllPresent,
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Mark All Present'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Inputs Card
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Class No.', style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _classNumberController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'e.g. 1'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date', style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _sessionDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) setState(() => _sessionDate = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                border: Border.all(color: AppColors.outlineVariant),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(dateFormat.format(_sessionDate), style: AppTypography.bodyMd.copyWith(fontSize: 14)),
                                  const Icon(Icons.calendar_today, size: 16, color: AppColors.secondary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Topic / Lecture Focus', style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _topicController,
                      decoration: const InputDecoration(hintText: 'e.g. Introduction to Adolescence Psychology'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Student List Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Student List (${_students.length})', style: AppTypography.titleMd.copyWith(fontSize: 16)),
                Text(
                  '${_attendanceStatusMap.values.where((v) => v == AttendanceStatus.present).length} Present',
                  style: AppTypography.labelMd.copyWith(color: AppColors.presentGreen, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          // Student Attendance List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final s = _students[index];
                final currentStatus = _attendanceStatusMap[s.id] ?? AttendanceStatus.present;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.1),
                          child: Text(
                            s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                            style: AppTypography.titleMd.copyWith(color: AppColors.primaryContainer, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name, style: AppTypography.titleMd.copyWith(fontSize: 15)),
                              Text(s.matricNumber, style: AppTypography.labelMd.copyWith(fontSize: 12)),
                            ],
                          ),
                        ),
                        AttendanceToggle(
                          status: currentStatus,
                          onChanged: (newStatus) {
                            setState(() => _attendanceStatusMap[s.id] = newStatus);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action Bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAttendance,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                    )
                  : const Text('Save Attendance'),
            ),
          ),
        ],
      ),
    );
  }
}
