import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
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

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
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

  Future<void> syncNow({String? lecturerId}) async {
    final fs = _firestore;
    if (fs == null) {
      _updateState(SyncState.synced);
      return;
    }

    try {
      final uid = lecturerId ?? 'lecturer_dr_ernest_001';
      final unSyncedCourses = await _db.getCoursesForLecturer(uid);
      final hasUnsynced = unSyncedCourses.any((c) => !c.synced);

      if (hasUnsynced) {
        _updateState(SyncState.syncing);

        for (final course in unSyncedCourses.where((c) => !c.synced)) {
          final docRef = fs
              .collection('lecturers')
              .doc(uid)
              .collection('courses')
              .doc(course.id);

          await docRef.set(course.toMap(), SetOptions(merge: true));

          // Sync students
          final students = await _db.getStudentsForCourse(course.id);
          for (final s in students.where((s) => !s.synced)) {
            await docRef.collection('students').doc(s.id).set(s.toMap(), SetOptions(merge: true));
            await _db.batchInsertStudents([s.copyWith(synced: true)]);
          }

          // Sync sessions
          final sessions = await _db.getSessionsForCourse(course.id);
          for (final sess in sessions.where((s) => !s.synced)) {
            await docRef.collection('sessions').doc(sess.id).set(sess.toMap(), SetOptions(merge: true));
            
            final records = await _db.getRecordsForSession(sess.id);
            for (final r in records.where((r) => !r.synced)) {
              await docRef
                  .collection('sessions')
                  .doc(sess.id)
                  .collection('records')
                  .doc(r.id)
                  .set(r.toMap(), SetOptions(merge: true));
            }
          }

          await _db.upsertCourse(course.copyWith(synced: true));
        }

        _updateState(SyncState.synced);
      } else {
        _updateState(SyncState.synced);
      }
    } catch (e) {
      debugPrint('Firestore sync background notice: $e');
      _updateState(SyncState.waitingToSync);
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
