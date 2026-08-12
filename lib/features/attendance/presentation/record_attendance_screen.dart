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
  bool _showSessionDetails = true; // collapsible session info section

  List<Student> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students.where((s) {
      final nameMatches = s.name.toLowerCase().contains(_searchQuery);
      final matricMatches = s.matricNumber.toLowerCase().contains(_searchQuery);
      return nameMatches || matricMatches;
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
        content: const Text('All students marked as Present'),
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
        content: const Text('All students marked as Absent'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                'Attendance saved. $_presentCount present, $_absentCount absent.'),
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
        appBar: AppBar(
          title: const Text('Record Attendance'),
          backgroundColor: AppColors.navyDeep,
          foregroundColor: Colors.white,
        ),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final dateFormat = DateFormat('EEE, d MMM yyyy');
    final pctPresent = _students.isNotEmpty
        ? (_presentCount / _students.length * 100)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Sticky Header ───────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A1628), Color(0xFF1A3A6B)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top nav row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
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
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _course?.courseCode ?? 'Record Attendance',
                                style: AppTypography.headlineMd.copyWith(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                _course?.courseTitle ?? '',
                                style: AppTypography.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Quick action buttons: All Present & All Absent
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _markAllPresent,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                      color: AppColors.success.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.done_all_rounded,
                                        size: 13, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      'All Present',
                                      style: AppTypography.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _markAllAbsent,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                      color: AppColors.error.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.remove_done_rounded,
                                        size: 13, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      'All Absent',
                                      style: AppTypography.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Live counter bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        _LiveCounter(
                            count: _presentCount,
                            label: 'Present',
                            color: AppColors.success),
                        const SizedBox(width: 20),
                        _LiveCounter(
                            count: _absentCount,
                            label: 'Absent',
                            color: AppColors.error),
                        const Spacer(),
                        // Mini progress bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${pctPresent.toStringAsFixed(0)}%',
                              style: AppTypography.titleSm.copyWith(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 80,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pctPresent / 100,
                                  minHeight: 5,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      pctPresent >= 75
                                          ? AppColors.success
                                          : AppColors.warning),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Collapsible session details
                  GestureDetector(
                    onTap: () => setState(
                        () => _showSessionDetails = !_showSessionDetails),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        border: Border(
                            top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1))),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _showSessionDetails
                                ? 'Session Details'
                                : 'Class #${_classNumberController.text} · ${_topicController.text}',
                            style: AppTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Icon(
                            _showSessionDetails
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expandable session detail inputs
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: _showSessionDetails
                        ? Container(
                            color: Colors.white.withValues(alpha: 0.04),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Class number
                                    SizedBox(
                                      width: 90,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Class No.',
                                            style: AppTypography.caption
                                                .copyWith(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.65),
                                                    fontSize: 11),
                                          ),
                                          const SizedBox(height: 6),
                                          TextField(
                                            controller: _classNumberController,
                                            keyboardType:
                                                TextInputType.number,
                                            style: AppTypography.titleSm
                                                .copyWith(color: Colors.white),
                                            decoration: InputDecoration(
                                              hintText: '1',
                                              hintStyle: AppTypography.bodyMd
                                                  .copyWith(
                                                      color: Colors.white
                                                          .withValues(alpha: 0.3)),
                                              filled: true,
                                              fillColor: Colors.white
                                                  .withValues(alpha: 0.08),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 10),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.15)),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.15)),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                    color: AppColors.accent,
                                                    width: 2),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // Date picker
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Session Date',
                                            style: AppTypography.caption
                                                .copyWith(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.65),
                                                    fontSize: 11),
                                          ),
                                          const SizedBox(height: 6),
                                          GestureDetector(
                                            onTap: () async {
                                              final picked =
                                                  await showDatePicker(
                                                context: context,
                                                initialDate: _sessionDate,
                                                firstDate: DateTime(2020),
                                                lastDate: DateTime(2030),
                                              );
                                              if (picked != null) {
                                                setState(() =>
                                                    _sessionDate = picked);
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 12, vertical: 11),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.08),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.15)),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    dateFormat.format(
                                                        _sessionDate),
                                                    style: AppTypography.bodyMd
                                                        .copyWith(
                                                            color: Colors.white,
                                                            fontSize: 13),
                                                  ),
                                                  Icon(
                                                      Icons
                                                          .calendar_today_rounded,
                                                      size: 14,
                                                      color: Colors.white
                                                          .withValues(alpha: 0.5)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Topic
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lecture Topic',
                                      style: AppTypography.caption.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.65),
                                          fontSize: 11),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _topicController,
                                      style: AppTypography.bodyMd.copyWith(
                                          color: Colors.white, fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText:
                                            'e.g. Introduction to Adolescence Psychology',
                                        hintStyle: AppTypography.bodyMd
                                            .copyWith(
                                                color: Colors.white
                                                    .withValues(alpha: 0.3),
                                                fontSize: 14),
                                        filled: true,
                                        fillColor:
                                            Colors.white.withValues(alpha: 0.08),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 11),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.white
                                                  .withValues(alpha: 0.15)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.white
                                                  .withValues(alpha: 0.15)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: AppColors.accent,
                                              width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // ── Search bar ──────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search student…',
                      prefixIcon:
                          const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_filteredStudents.length} students',
                  style: AppTypography.caption
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Student List ─────────────────────────────────────────────
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No students found in this course.'
                          : 'No students matching "$_searchQuery"',
                      style: AppTypography.bodyMd,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final s = _filteredStudents[index];
                      final currentStatus =
                          _attendanceStatusMap[s.id] ?? AttendanceStatus.present;
                      final isPresent =
                          currentStatus == AttendanceStatus.present;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isPresent
                              ? AppColors.surface
                              : AppColors.errorBg.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isPresent
                                ? AppColors.border
                                : AppColors.error.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isPresent
                                    ? AppColors.accentLight
                                    : AppColors.errorBg,
                                child: Text(
                                  s.name.isNotEmpty
                                      ? s.name[0].toUpperCase()
                                      : 'S',
                                  style: AppTypography.titleSm.copyWith(
                                    color: isPresent
                                        ? AppColors.accent
                                        : AppColors.error,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Name + matric
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: AppTypography.titleSm.copyWith(
                                        fontSize: 14,
                                        color: isPresent
                                            ? AppColors.textPrimary
                                            : AppColors.error,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      s.matricNumber,
                                      style: AppTypography.caption,
                                    ),
                                  ],
                                ),
                              ),

                              // Attendance toggle
                              AttendanceToggle(
                                status: currentStatus,
                                onChanged: (newStatus) {
                                  setState(() =>
                                      _attendanceStatusMap[s.id] = newStatus);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ── Bottom Save Bar ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Summary chips
                  _SummaryChip(
                      count: _presentCount,
                      label: 'Present',
                      color: AppColors.success,
                      bg: AppColors.successBg),
                  const SizedBox(width: 8),
                  _SummaryChip(
                      count: _absentCount,
                      label: 'Absent',
                      color: AppColors.error,
                      bg: AppColors.errorBg),
                  const Spacer(),

                  // Save button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAttendance,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(130, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Attendance'),
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

// ── Small Widgets ─────────────────────────────────────────────────────────────

class _LiveCounter extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _LiveCounter({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: AppTypography.statMd.copyWith(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final Color bg;

  const _SummaryChip({
    required this.count,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: AppTypography.titleSm.copyWith(
                color: color, fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
                color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
