import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/sync/sync_service.dart';
import '../../shared/models/lecturer_user.dart';
import '../../shared/models/course.dart';
import '../../shared/models/student.dart';
import '../../shared/models/attendance_session.dart';
import '../../shared/models/attendance_record.dart';
import 'auth_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final syncServiceProvider = ChangeNotifierProvider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncService(db);
});

class CurrentUserNotifier extends StateNotifier<LecturerUser?> {
  final AuthService _authService;
  final AppDatabase _db;
  StreamSubscription? _authSub;

  CurrentUserNotifier(this._authService, this._db) : super(null) {
    _init();
  }

  Future<void> _init() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      state = user;
      await _db.saveUser(user);
    }

    _authSub = _authService.authStateChanges?.listen((data) async {
      final updatedUser = _authService.getCurrentUser();
      if (updatedUser != null) {
        state = updatedUser;
        await _db.saveUser(updatedUser);
      } else if (data.session == null) {
        state = null;
      }
    });
  }

  Future<void> updateUserProfile(LecturerUser user) async {
    state = user;
    await _db.saveUser(user);
  }

  Future<void> signInWithEmail(String email, String password) async {
    final user = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    state = user;
    await _db.saveUser(user);
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await _authService.signUpWithEmailAndPassword(
      email: email,
      password: password,
      fullName: fullName,
    );
    // Note: If email confirmation is required, state will update via stream when confirmed.
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      state = currentUser;
      await _db.saveUser(currentUser);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordReset(email);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = null;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, LecturerUser?>((ref) {
  final auth = ref.watch(authServiceProvider);
  final db = ref.watch(databaseProvider);
  return CurrentUserNotifier(auth, db);
});

final coursesStreamProvider = StreamProvider.autoDispose<List<Course>>((ref) {
  final user = ref.watch(currentUserProvider);
  final db = ref.watch(databaseProvider);
  if (user == null) return Stream.value([]);
  return db.watchCoursesForLecturer(user.id);
});

final studentsStreamProvider = StreamProvider.autoDispose.family<List<Student>, String>((ref, courseId) {
  final db = ref.watch(databaseProvider);
  return db.watchStudentsForCourse(courseId);
});

final sessionsStreamProvider = StreamProvider.autoDispose.family<List<AttendanceSession>, String>((ref, courseId) {
  final db = ref.watch(databaseProvider);
  return db.watchSessionsForCourse(courseId);
});

final sessionRecordsFutureProvider = FutureProvider.autoDispose.family<List<AttendanceRecord>, String>((ref, sessionId) async {
  final db = ref.watch(databaseProvider);
  return db.getRecordsForSession(sessionId);
});

final allCourseRecordsFutureProvider = FutureProvider.autoDispose.family<List<AttendanceRecord>, String>((ref, courseId) async {
  final db = ref.watch(databaseProvider);
  return db.getAllRecordsForCourse(courseId);
});
