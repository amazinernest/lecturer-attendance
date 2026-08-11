import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';

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

  /// Syncs local Drift SQLite data to Supabase Postgres database tables
  Future<void> syncNow({String? lecturerId}) async {
    final client = _supabaseClient;
    final currentUser = client?.auth.currentUser;

    if (client == null || currentUser == null) {
      _updateState(SyncState.synced);
      return;
    }

    try {
      final uid = lecturerId ?? currentUser.id;
      final unSyncedCourses = await _db.getCoursesForLecturer(uid);
      final hasUnsynced = unSyncedCourses.any((c) => !c.synced);

      if (hasUnsynced || unSyncedCourses.isNotEmpty) {
        _updateState(SyncState.syncing);

        for (final course in unSyncedCourses) {
          // 1. Sync Course row to Supabase
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

          // 2. Sync Students for Course
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

          // 3. Sync Attendance Sessions for Course
          final sessions = await _db.getSessionsForCourse(course.id);
          final unsyncedSessions = sessions.where((s) => !s.synced).toList();
          if (unsyncedSessions.isNotEmpty) {
            final sessionRows = unsyncedSessions.map((s) => {
              'id': s.id,
              'course_id': course.id,
              'class_number': s.classNumber,
              'date': s.date.toIso8601String(),
              'topic': s.topic,
              'created_at': s.createdAt.toIso8601String(),
            }).toList();

            await client.from('attendance_sessions').upsert(sessionRows);

            for (final sess in unsyncedSessions) {
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
              }
            }
          }

          if (!course.synced) {
            await _db.upsertCourse(course.copyWith(synced: true));
          }
        }

        _updateState(SyncState.synced);
      } else {
        _updateState(SyncState.synced);
      }
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
