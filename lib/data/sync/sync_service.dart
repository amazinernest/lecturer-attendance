import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import '../../shared/models/course.dart';
import '../../shared/models/student.dart';
import '../../shared/models/attendance_session.dart';
import '../../shared/models/attendance_record.dart';

enum SyncState {
  synced,
  waitingToSync,
  syncing,
  error;

  String get label {
    switch (this) {
      case SyncState.synced:
        return 'Synced';
      case SyncState.waitingToSync:
        return 'Waiting to sync';
      case SyncState.syncing:
        return 'Syncing...';
      case SyncState.error:
        return 'Sync error';
    }
  }
}

class SyncService extends ChangeNotifier {
  final AppDatabase _db;
  SyncState _state = SyncState.synced;
  Timer? _syncTimer;

  SyncService(this._db) {
    _startPeriodicSync();
  }

  SupabaseClient? get _supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SyncState get state => _state;

  void _updateState(SyncState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      syncNow();
    });
  }

  /// Syncs local Drift SQLite data with Supabase Postgres database tables.
  /// Phase 1: Pulls remote data from Supabase for this lecturer into local SQLite.
  /// Phase 2: Pushes any unsynced local records up to Supabase.
  Future<void> syncNow({String? lecturerId}) async {
    final client = _supabaseClient;
    final currentUser = client?.auth.currentUser;

    if (client == null || currentUser == null) {
      _updateState(SyncState.synced);
      return;
    }

    try {
      final uid = lecturerId ?? currentUser.id;
      _updateState(SyncState.syncing);

      // ========================================================
      // PHASE 1: CLOUD-TO-LOCAL RESTORE (Pull Lecturer Data)
      // ========================================================
      // 1. Fetch all courses belonging to this lecturer from Supabase
      try {
        final remoteCoursesRes = await client
            .from('courses')
            .select()
            .eq('lecturer_id', uid);

        final List<dynamic> remoteCourses = remoteCoursesRes;

        if (remoteCourses.isNotEmpty) {
          final List<String> courseIds = [];
          for (final dynamic item in remoteCourses) {
            final row = item as Map<String, dynamic>;
            final cId = row['id'] as String;
            courseIds.add(cId);
            final course = Course(
              id: cId,
              lecturerId: row['lecturer_id'] as String? ?? uid,
              courseCode: row['course_code'] as String? ?? '',
              courseTitle: row['course_title'] as String? ?? '',
              department: row['department'] as String? ?? '',
              level: row['level'] as String? ?? '',
              semester: row['semester'] as String? ?? '',
              academicSession: row['academic_session'] as String? ?? '',
              expectedClasses: row['expected_classes'] as int? ?? 15,
              status: CourseStatus.fromValue(row['status'] as String?),
              createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
              synced: true,
            );
            await _db.upsertCourse(course);
          }

          // 2. Fetch students for all lecturer courses
          if (courseIds.isNotEmpty) {
            final remoteStudentsRes = await client
                .from('students')
                .select()
                .inFilter('course_id', courseIds);

            final List<dynamic> remoteStudents = remoteStudentsRes;
            if (remoteStudents.isNotEmpty) {
              final studentsToInsert = remoteStudents.map<Student>((dynamic item) {
                final row = item as Map<String, dynamic>;
                return Student(
                  id: row['id'] as String,
                  courseId: row['course_id'] as String,
                  name: row['name'] as String? ?? '',
                  matricNumber: row['matric_number'] as String? ?? '',
                  createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
                  updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
                  synced: true,
                );
              }).toList();
              await _db.batchInsertStudents(studentsToInsert);
            }

            // 3. Fetch attendance sessions
            final remoteSessionsRes = await client
                .from('attendance_sessions')
                .select()
                .inFilter('course_id', courseIds);

            final List<dynamic> remoteSessions = remoteSessionsRes;
            if (remoteSessions.isNotEmpty) {
              final sessionsToInsert = remoteSessions.map<AttendanceSession>((dynamic item) {
                final row = item as Map<String, dynamic>;
                return AttendanceSession(
                  id: row['id'] as String,
                  courseId: row['course_id'] as String,
                  classNumber: row['class_number'] as int? ?? 1,
                  date: DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now(),
                  topic: row['topic'] as String? ?? '',
                  createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
                  synced: true,
                );
              }).toList();
              await _db.batchInsertSessions(sessionsToInsert);

              // 4. Fetch attendance records for these sessions
              final sessionIds = remoteSessions.map((dynamic s) => (s as Map<String, dynamic>)['id'] as String).toList();
              if (sessionIds.isNotEmpty) {
                final remoteRecordsRes = await client
                    .from('attendance_records')
                    .select()
                    .inFilter('attendance_session_id', sessionIds);

                final List<dynamic> remoteRecords = remoteRecordsRes;
                if (remoteRecords.isNotEmpty) {
                  final recordsToInsert = remoteRecords.map<AttendanceRecord>((dynamic item) {
                    final row = item as Map<String, dynamic>;
                    return AttendanceRecord(
                      id: row['id'] as String,
                      attendanceSessionId: row['attendance_session_id'] as String,
                      studentId: row['student_id'] as String,
                      status: AttendanceStatus.fromValue(row['status'] as String?),
                      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
                      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
                      synced: true,
                    );
                  }).toList();
                  await _db.batchInsertRecords(recordsToInsert);
                }
              }
            }
          }
        }
      } catch (pullError) {
        debugPrint('Supabase cloud pull note: $pullError');
      }

      // ========================================================
      // PHASE 2: LOCAL-TO-CLOUD PUSH (Sync Local Changes)
      // ========================================================
      final localCourses = await _db.getCoursesForLecturer(uid);
      for (final course in localCourses) {
        // Push Course row if unsynced
        if (!course.synced) {
          await client.from('courses').upsert({
            'id': course.id,
            'lecturer_id': uid,
            'course_code': course.courseCode,
            'course_title': course.courseTitle,
            'department': course.department,
            'level': course.level,
            'semester': course.semester,
            'academic_session': course.academicSession,
            'expected_classes': course.expectedClasses,
            'status': course.status.toValue(),
            'created_at': course.createdAt.toIso8601String(),
            'updated_at': course.updatedAt.toIso8601String(),
          });
          await _db.upsertCourse(course.copyWith(synced: true));
        }

        // Push Students for Course
        final students = await _db.getStudentsForCourse(course.id);
        final unsyncedStudents = students.where((s) => !s.synced).toList();
        if (unsyncedStudents.isNotEmpty) {
          final studentRows = unsyncedStudents.map((s) => {
            'id': s.id,
            'course_id': course.id,
            'name': s.name,
            'matric_number': s.matricNumber,
            'created_at': s.createdAt.toIso8601String(),
            'updated_at': s.updatedAt.toIso8601String(),
          }).toList();

          await client.from('students').upsert(studentRows);
          await _db.batchInsertStudents(unsyncedStudents.map((s) => s.copyWith(synced: true)).toList());
        }

        // Push Attendance Sessions and Records for Course
        final sessions = await _db.getSessionsForCourse(course.id);
        for (final sess in sessions) {
          if (!sess.synced) {
            await client.from('attendance_sessions').upsert({
              'id': sess.id,
              'course_id': course.id,
              'class_number': sess.classNumber,
              'date': sess.date.toIso8601String(),
              'topic': sess.topic,
              'created_at': sess.createdAt.toIso8601String(),
            });
            await _db.batchInsertSessions([sess.copyWith(synced: true)]);
          }

          final records = await _db.getRecordsForSession(sess.id);
          final unsyncedRecords = records.where((r) => !r.synced).toList();
          if (unsyncedRecords.isNotEmpty) {
            final recordRows = unsyncedRecords.map((r) => {
              'id': r.id,
              'attendance_session_id': sess.id,
              'student_id': r.studentId,
              'status': r.status.toValue(),
              'created_at': r.createdAt.toIso8601String(),
              'updated_at': r.updatedAt.toIso8601String(),
            }).toList();

            await client.from('attendance_records').upsert(recordRows);
            await _db.batchInsertRecords(unsyncedRecords.map((r) => r.copyWith(synced: true)).toList());
          }
        }
      }

      _updateState(SyncState.synced);
    } catch (e) {
      debugPrint('Supabase database sync notice: $e');
      _updateState(SyncState.waitingToSync);
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
