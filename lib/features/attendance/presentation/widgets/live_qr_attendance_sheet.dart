import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/course.dart';
import '../../../../shared/models/student.dart';
import '../../../../shared/models/attendance_record.dart';
import '../../../../core/utils/report_exporter.dart';

class LiveQrAttendanceSheet extends StatefulWidget {
  final Course course;
  final int classNumber;
  final String topic;
  final DateTime sessionDate;
  final List<Student> students;
  final Map<String, AttendanceStatus> initialStatusMap;
  final String sessionId;
  final Function(Map<String, AttendanceStatus> updatedMap) onAttendanceUpdated;

  const LiveQrAttendanceSheet({
    super.key,
    required this.course,
    required this.classNumber,
    required this.topic,
    required this.sessionDate,
    required this.students,
    required this.initialStatusMap,
    required this.sessionId,
    required this.onAttendanceUpdated,
  });

  @override
  State<LiveQrAttendanceSheet> createState() => _LiveQrAttendanceSheetState();
}

class _LiveQrAttendanceSheetState extends State<LiveQrAttendanceSheet> {
  late Map<String, AttendanceStatus> _statusMap;
  late String _securityPin;
  bool _isSessionOpen = true;
  bool _isGeneratingPdf = false;
  final List<Student> _recentCheckIns = [];
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _statusMap = Map.from(widget.initialStatusMap);
    _securityPin = _generateRandomPin();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _generateRandomPin() {
    final rng = Random();
    return (1000 + rng.nextInt(9000)).toString();
  }

  void _regeneratePin() {
    HapticFeedback.mediumImpact();
    setState(() {
      _securityPin = _generateRandomPin();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New Security PIN generated: $_securityPin'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int get _presentCount =>
      _statusMap.values.where((v) => v == AttendanceStatus.present).length;
  int get _totalCount => widget.students.length;
  double get _presentPct =>
      _totalCount > 0 ? (_presentCount / _totalCount) : 0.0;

  String get _portalUrl {
    final baseUrl = 'https://amazinernest.github.io/lecturer-attendance/checkin';
    return '$baseUrl?courseId=${Uri.encodeComponent(widget.course.id)}'
        '&courseCode=${Uri.encodeComponent(widget.course.courseCode)}'
        '&courseTitle=${Uri.encodeComponent(widget.course.courseTitle)}'
        '&classNum=${widget.classNumber}'
        '&pin=$_securityPin'
        '&sessionId=${Uri.encodeComponent(widget.sessionId)}';
  }

  void _markStudentPresent(Student student) {
    if (_statusMap[student.id] == AttendanceStatus.present) return;

    HapticFeedback.lightImpact();
    setState(() {
      _statusMap[student.id] = AttendanceStatus.present;
      if (!_recentCheckIns.any((s) => s.id == student.id)) {
        _recentCheckIns.insert(0, student);
        if (_recentCheckIns.length > 5) {
          _recentCheckIns.removeLast();
        }
      }
    });
    widget.onAttendanceUpdated(_statusMap);
  }

  void _copyAttendanceLink() {
    Clipboard.setData(ClipboardData(text: _portalUrl));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Student attendance link copied to clipboard!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareAttendanceLink() {
    final message = '''
*${widget.course.courseCode} - Class #${widget.classNumber} Attendance*
Topic: ${widget.topic.isNotEmpty ? widget.topic : 'Regular Lecture'}
Security PIN: $_securityPin

Tick your name on the roster:
$_portalUrl

Notice: Locked to 1 submission per physical phone. Proxy signing is prohibited.
''';
    Clipboard.setData(ClipboardData(text: message));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.share_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Class message with link & PIN copied! Paste into WhatsApp/LMS.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Simulator for pitching and demonstrations: simulate student scanning and submitting
  void _simulateStudentCheckIn() {
    if (!_isSessionOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session is locked. Reopen session to accept check-ins.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Find first absent student
    final absentStudents = widget.students
        .where((s) => _statusMap[s.id] != AttendanceStatus.present)
        .toList();

    if (absentStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All enrolled students are already marked Present!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final randomStudent = absentStudents[Random().nextInt(absentStudents.length)];
    _markStudentPresent(randomStudent);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🎉 Verified Check-In: ${randomStudent.name} (${randomStudent.matricNumber})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handlePrintQrSheet() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfBytes = await ReportExporter.generateQrAttendanceSheetPdf(
        course: widget.course,
        classNumber: widget.classNumber,
        topic: widget.topic,
        date: widget.sessionDate,
        qrData: _portalUrl,
        pinCode: _securityPin,
        totalStudents: _totalCount,
      );

      await ReportExporter.printOrSharePdf(
        pdfBytes: pdfBytes,
        filename: '${widget.course.courseCode}_Class${widget.classNumber}_QR_Attendance_Sheet',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not generate QR sheet: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.course.courseCode,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'CLASS #${widget.classNumber}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Live Dynamic Check-In & Anti-Proxy Station',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  // Session status & security banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isSessionOpen
                            ? [
                                const Color(0xFF0F2537),
                                const Color(0xFF0A192F),
                              ]
                            : [
                                const Color(0xFF2D1515),
                                const Color(0xFF1F0C0C),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isSessionOpen
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
                            : const Color(0xFFEF4444).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isSessionOpen
                                ? const Color(0xFF34D399)
                                : const Color(0xFFF87171),
                            boxShadow: [
                              BoxShadow(
                                color: _isSessionOpen
                                    ? const Color(0xFF34D399).withValues(alpha: 0.8)
                                    : const Color(0xFFF87171).withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isSessionOpen
                                    ? 'SESSION ACTIVE & ACCEPTING SCANS'
                                    : 'SESSION LOCKED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: _isSessionOpen
                                      ? const Color(0xFF7DD3FC)
                                      : const Color(0xFFFCA5A5),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isSessionOpen
                                    ? 'Students can scan with their phone camera to sign present'
                                    : 'No new check-ins allowed',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _isSessionOpen,
                          activeTrackColor: const Color(0xFF38BDF8),
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            setState(() => _isSessionOpen = val);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // The Big Dynamic QR Code Presentation Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Security PIN Callout
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield_rounded,
                                color: Color(0xFFD97706),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'SESSION PIN: ',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _securityPin,
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: _regeneratePin,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // QR Code Graphic
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: _portalUrl,
                            version: QrVersions.auto,
                            size: 210.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0F172A),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Anti-Proxy Guard Notice
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Anti-Proxy: Locked to 1 submission per physical phone',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Direct Student Link & Roster Sharing Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.link_rounded,
                                color: Color(0xFF2563EB),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Student Roster Sign-In Link',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Students open this link, tap their name on the class roster, and tick present. Each submission is permanently locked to one physical device.',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _copyAttendanceLink,
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text(
                                  'Copy Link',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF2563EB),
                                  side: const BorderSide(color: Color(0xFF2563EB)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _shareAttendanceLink,
                                icon: const Icon(Icons.share_rounded, size: 16),
                                label: const Text(
                                  'Share to Class',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Real-time Progress Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Live Attendance:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$_presentCount / $_totalCount Present',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${(_presentPct * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _presentPct,
                            minHeight: 8,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Pitch & Demo Superpower: Simulate Student Check-In Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: Color(0xFF6366F1),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Live Demonstration Tool',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Test live student sign-in during pitches to demonstrate instant synchronization without needing extra phones.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _simulateStudentCheckIn,
                            icon: const Icon(Icons.touch_app_rounded, size: 18),
                            label: const Text(
                              'Simulate 1 Student Scan & Submit',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Recent check-in ticker
                  if (_recentCheckIns.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'RECENT LIVE CHECK-INS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._recentCheckIns.map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                s.matricNumber,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Action Dock
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.8), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Print / Share Paper QR Sheet CTA
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isGeneratingPdf ? null : _handlePrintQrSheet,
                    icon: _isGeneratingPdf
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print_rounded, size: 18),
                    label: const Text(
                      'Print QR Sheet',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Apply & Return to Attendance CTA
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      widget.onAttendanceUpdated(_statusMap);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Attendance updated: $_presentCount Present out of $_totalCount!'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text(
                      'Apply to Session',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
