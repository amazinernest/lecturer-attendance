import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  ConsumerState<RecordAttendanceScreen> createState() =>
      _RecordAttendanceScreenState();
}

class _RecordAttendanceScreenState
    extends ConsumerState<RecordAttendanceScreen> {
  final _uuid = const Uuid();
  late TextEditingController _topicController;
  late TextEditingController _classNumberController;
  DateTime _sessionDate = DateTime.now();

  Map<String, AttendanceStatus> _attendanceStatusMap = {};
  bool _isLoading = true;
  bool _isSaving = false;
  List<Student> _students = [];
  Course? _course;

  late TextEditingController _searchController;
  String _searchQuery = '';
  String _filterMode = 'All'; // 'All', 'Present', 'Absent'

  List<Student> get _filteredStudents {
    return _students.where((s) {
      // Search filter
      final q = _searchQuery;
      final nameMatches = q.isEmpty || s.name.toLowerCase().contains(q);
      final matricMatches = q.isEmpty || s.matricNumber.toLowerCase().contains(q);
      if (!nameMatches && !matricMatches) return false;

      // Status filter
      final status = _attendanceStatusMap[s.id] ?? AttendanceStatus.present;
      if (_filterMode == 'Present') return status == AttendanceStatus.present;
      if (_filterMode == 'Absent') return status == AttendanceStatus.absent;
      return true;
    }).toList();
  }

  int get _presentCount =>
      _attendanceStatusMap.values.where((v) => v == AttendanceStatus.present).length;
  int get _absentCount =>
      _attendanceStatusMap.values.where((v) => v == AttendanceStatus.absent).length;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: 'Lecture Review');
    _classNumberController = TextEditingController(text: '1');
    _searchController = TextEditingController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _classNumberController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final db = ref.read(databaseProvider);
    final course = await db.getCourseById(widget.courseId);
    final students = await db.getStudentsForCourse(widget.courseId);
    final existingSessions = await db.getSessionsForCourse(widget.courseId);

    final statusMap = <String, AttendanceStatus>{};

    if (widget.existingSessionId != null) {
      final existingSession = existingSessions
          .firstWhere((s) => s.id == widget.existingSessionId);
      _topicController.text = existingSession.topic;
      _classNumberController.text = '${existingSession.classNumber}';
      _sessionDate = existingSession.date;

      final existingRecords =
          await db.getRecordsForSession(widget.existingSessionId!);
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
    HapticFeedback.mediumImpact();
    setState(() {
      for (final s in _students) {
        _attendanceStatusMap[s.id] = AttendanceStatus.present;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('All ${_students.length} students marked Present'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _markAllAbsent() {
    HapticFeedback.mediumImpact();
    setState(() {
      for (final s in _students) {
        _attendanceStatusMap[s.id] = AttendanceStatus.absent;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('All ${_students.length} students marked Absent'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSessionConfigModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SessionConfigModal(
        classNumberController: _classNumberController,
        topicController: _topicController,
        sessionDate: _sessionDate,
        onDateSelected: (newDate) {
          setState(() => _sessionDate = newDate);
        },
      ),
    );
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No students in this course to record attendance for.')),
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
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Session #$classNum saved! $_presentCount Present • $_absentCount Absent'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save attendance: $e'),
              backgroundColor: AppColors.error),
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
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final totalCount = _students.length;
    final pctPresent = totalCount > 0 ? (_presentCount / totalCount * 100) : 0.0;
    final dateStr = DateFormat('EEE, d MMM yyyy').format(_sessionDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── 1. ULTRA-CLEAN HEADER ──────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF070E1E),
                  Color(0xFF0F2248),
                  Color(0xFF193B7B),
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x2A000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Column(
                  children: [
                    // Navigation row
                    Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _course?.courseCode ?? 'Course',
                                    style: const TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF38BDF8)
                                          .withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'CLASS #${_classNumberController.text}',
                                      style: const TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        color: Color(0xFF7DD3FC),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _course?.courseTitle ?? '',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Session Config Trigger Pill
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _showSessionConfigModal,
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.tune_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Config',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Topic & Date Strip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF60A5FA)
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.topic_outlined,
                              size: 14,
                              color: Color(0xFF93C5FD),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _topicController.text.isNotEmpty
                                      ? _topicController.text
                                      : 'General Lecture Session',
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _showSessionConfigModal,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 15,
                                color: Color(0xFF93C5FD),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Live Stats & Batch Actions Bar
                    Row(
                      children: [
                        // Live Progress Counter
                        Expanded(
                          child: Row(
                            children: [
                              _HeaderCountPill(
                                count: _presentCount,
                                label: 'Present',
                                color: const Color(0xFF10B981),
                                bg: const Color(0xFF10B981).withValues(alpha: 0.2),
                              ),
                              const SizedBox(width: 8),
                              _HeaderCountPill(
                                count: _absentCount,
                                label: 'Absent',
                                color: const Color(0xFFEF4444),
                                bg: const Color(0xFFEF4444).withValues(alpha: 0.2),
                              ),
                            ],
                          ),
                        ),
                        // Fast Batch Actions
                        Row(
                          children: [
                            _BatchActionButton(
                              label: 'All Present',
                              icon: Icons.done_all_rounded,
                              color: const Color(0xFF34D399),
                              onTap: _markAllPresent,
                            ),
                            const SizedBox(width: 6),
                            _BatchActionButton(
                              label: 'All Absent',
                              icon: Icons.remove_done_rounded,
                              color: const Color(0xFFF87171),
                              onTap: _markAllAbsent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 2. SEARCH & STATUS FILTER STRIP ────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Search bar
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(
                              () => _searchQuery = val.trim().toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Search student name or matric #...',
                            hintStyle: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                            prefixIcon: const Icon(Icons.search_rounded,
                                size: 18, color: AppColors.textMuted),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded,
                                        size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Perfectly Balanced Segmented Filter Tabs (All, Present, Absent)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FilterTabItem(
                          label: 'All',
                          count: totalCount,
                          isSelected: _filterMode == 'All',
                          activeColor: AppColors.navyDeep,
                          onTap: () => setState(() => _filterMode = 'All'),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _FilterTabItem(
                          label: 'Present',
                          count: _presentCount,
                          isSelected: _filterMode == 'Present',
                          activeColor: const Color(0xFF10B981),
                          indicatorColor: const Color(0xFF10B981),
                          onTap: () => setState(() => _filterMode = 'Present'),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _FilterTabItem(
                          label: 'Absent',
                          count: _absentCount,
                          isSelected: _filterMode == 'Absent',
                          activeColor: const Color(0xFFEF4444),
                          indicatorColor: const Color(0xFFEF4444),
                          onTap: () => setState(() => _filterMode = 'Absent'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── 3. STUDENT LIST ───────────────────────────────────────────
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            size: 48,
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No students found matching "$_searchQuery"'
                                : 'No students found in this category.',
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final s = _filteredStudents[index];
                      final currentStatus = _attendanceStatusMap[s.id] ??
                          AttendanceStatus.present;
                      final isPresent =
                          currentStatus == AttendanceStatus.present;

                      return _StudentAttendanceCard(
                        student: s,
                        index: index + 1,
                        isPresent: isPresent,
                        onToggle: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _attendanceStatusMap[s.id] = isPresent
                                ? AttendanceStatus.absent
                                : AttendanceStatus.present;
                          });
                        },
                      );
                    },
                  ),
          ),

          // ── 4. FLOATING BOTTOM ACTION DOCK ────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.9), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Attendance Rate Indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$_presentCount / $totalCount',
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (pctPresent >= 75
                                      ? AppColors.successBg
                                      : AppColors.warningBg),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${pctPresent.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: (pctPresent >= 75
                                    ? AppColors.success
                                    : AppColors.warning),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Total Present Rate',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 20),

                  // Save & Finalize Attendance CTA
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSaving ? null : _saveAttendance,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF2563EB),
                                Color(0xFF1D4ED8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.save_rounded,
                                          color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Save Attendance',
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STUDENT ATTENDANCE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _StudentAttendanceCard extends StatelessWidget {
  final Student student;
  final int index;
  final bool isPresent;
  final VoidCallback onToggle;

  const _StudentAttendanceCard({
    required this.student,
    required this.index,
    required this.isPresent,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: isPresent
            ? AppColors.surface
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPresent
              ? AppColors.border
              : const Color(0xFFFCA5A5).withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          splashColor: (isPresent ? AppColors.success : AppColors.error)
              .withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Index / Avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isPresent
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      student.name.isNotEmpty
                          ? student.name[0].toUpperCase()
                          : '$index',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        color: isPresent
                            ? AppColors.accent
                            : AppColors.error,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name & Matric
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isPresent
                              ? AppColors.textPrimary
                              : const Color(0xFF991B1B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            student.matricNumber,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              color: isPresent
                                  ? AppColors.textSecondary
                                  : const Color(0xFFB91C1C).withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '•  #$index',
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Attendance Toggle Button
                AttendanceToggle(
                  status: isPresent
                      ? AttendanceStatus.present
                      : AttendanceStatus.absent,
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER COMPONENT PILLS & BUTTONS
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderCountPill extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final Color bg;

  const _HeaderCountPill({
    required this.count,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BatchActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTabItem extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color activeColor;
  final Color? indicatorColor;
  final VoidCallback onTap;

  const _FilterTabItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.activeColor,
    this.indicatorColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (indicatorColor != null && !isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4.5),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SESSION CONFIGURATION BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _SessionConfigModal extends StatefulWidget {
  final TextEditingController classNumberController;
  final TextEditingController topicController;
  final DateTime sessionDate;
  final ValueChanged<DateTime> onDateSelected;

  const _SessionConfigModal({
    required this.classNumberController,
    required this.topicController,
    required this.sessionDate,
    required this.onDateSelected,
  });

  @override
  State<_SessionConfigModal> createState() => _SessionConfigModalState();
}

class _SessionConfigModalState extends State<_SessionConfigModal> {
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.sessionDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Session Settings',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Class Number
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Class #',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: widget.classNumberController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Date Picker
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Session Date',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _currentDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _currentDate = picked);
                              widget.onDateSelected(picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('EEE, d MMM yyyy')
                                      .format(_currentDate),
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Icon(Icons.calendar_today_rounded,
                                    size: 16, color: AppColors.accent),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Topic
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lecture Topic',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: widget.topicController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Memory Management & Paging Algorithms',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyDeep,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
