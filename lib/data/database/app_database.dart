import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../shared/models/lecturer_user.dart';
import '../../shared/models/course.dart';
import '../../shared/models/student.dart';
import '../../shared/models/attendance_session.dart';
import '../../shared/models/attendance_record.dart';

part 'app_database.g.dart';

@DataClassName('UserRow')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get photoUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CourseRow')
class Courses extends Table {
  TextColumn get id => text()();
  TextColumn get lecturerId => text()();
  TextColumn get courseCode => text()();
  TextColumn get courseTitle => text()();
  TextColumn get department => text()();
  TextColumn get level => text()();
  TextColumn get semester => text()();
  TextColumn get academicSession => text()();
  IntColumn get expectedClasses => integer().withDefault(const Constant(15))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('StudentRow')
class Students extends Table {
  TextColumn get id => text()();
  TextColumn get courseId => text()();
  TextColumn get name => text()();
  TextColumn get matricNumber => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AttendanceSessionRow')
class AttendanceSessions extends Table {
  TextColumn get id => text()();
  TextColumn get courseId => text()();
  IntColumn get classNumber => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get topic => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AttendanceRecordRow')
class AttendanceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get attendanceSessionId => text()();
  TextColumn get studentId => text()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Users, Courses, Students, AttendanceSessions, AttendanceRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // --- CRUD HELPERS ---

  // User
  Future<void> saveUser(LecturerUser user) async {
    await into(users).insertOnConflictUpdate(
      UserRow(
        id: user.id,
        name: user.name,
        email: user.email,
        photoUrl: user.photoUrl,
        createdAt: user.createdAt,
      ),
    );
  }

  Future<LecturerUser?> getUser(String id) async {
    final query = select(users)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return LecturerUser(
      id: row.id,
      name: row.name,
      email: row.email,
      photoUrl: row.photoUrl,
      createdAt: row.createdAt,
    );
  }

  // Courses
  Stream<List<Course>> watchCoursesForLecturer(String lecturerId) {
    final query = select(courses)..where((t) => t.lecturerId.equals(lecturerId));
    return query.watch().map((rows) => rows.map(_courseFromRow).toList());
  }

  Future<List<Course>> getCoursesForLecturer(String lecturerId) async {
    final query = select(courses)..where((t) => t.lecturerId.equals(lecturerId));
    final rows = await query.get();
    return rows.map(_courseFromRow).toList();
  }

  Future<Course?> getCourseById(String courseId) async {
    final query = select(courses)..where((t) => t.id.equals(courseId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _courseFromRow(row);
  }

  Future<void> upsertCourse(Course course) async {
    await into(courses).insertOnConflictUpdate(
      CourseRow(
        id: course.id,
        lecturerId: course.lecturerId,
        courseCode: course.courseCode,
        courseTitle: course.courseTitle,
        department: course.department,
        level: course.level,
        semester: course.semester,
        academicSession: course.academicSession,
        expectedClasses: course.expectedClasses,
        status: course.status.toValue(),
        createdAt: course.createdAt,
        updatedAt: course.updatedAt,
        synced: course.synced,
      ),
    );
  }

  Future<void> deleteCourse(String courseId) async {
    await transaction(() async {
      final sessionIdsQuery = select(attendanceSessions)..where((t) => t.courseId.equals(courseId));
      final sessions = await sessionIdsQuery.get();
      for (final s in sessions) {
        await (delete(attendanceRecords)..where((t) => t.attendanceSessionId.equals(s.id))).go();
      }
      await (delete(attendanceSessions)..where((t) => t.courseId.equals(courseId))).go();
      await (delete(students)..where((t) => t.courseId.equals(courseId))).go();
      await (delete(courses)..where((t) => t.id.equals(courseId))).go();
    });
  }

  // Students
  Stream<List<Student>> watchStudentsForCourse(String courseId) {
    final query = select(students)..where((t) => t.courseId.equals(courseId));
    return query.watch().map((rows) => rows.map(_studentFromRow).toList());
  }

  Future<List<Student>> getStudentsForCourse(String courseId) async {
    final query = select(students)..where((t) => t.courseId.equals(courseId));
    final rows = await query.get();
    return rows.map(_studentFromRow).toList();
  }

  Future<void> batchInsertStudents(List<Student> newStudents) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        students,
        newStudents.map((s) => StudentRow(
          id: s.id,
          courseId: s.courseId,
          name: s.name,
          matricNumber: s.matricNumber,
          createdAt: s.createdAt,
          updatedAt: s.updatedAt,
          synced: s.synced,
        )).toList(),
      );
    });
  }

  // Sessions & Attendance Records
  Stream<List<AttendanceSession>> watchSessionsForCourse(String courseId) {
    final query = select(attendanceSessions)
      ..where((t) => t.courseId.equals(courseId))
      ..orderBy([(t) => OrderingTerm.desc(t.classNumber)]);
    return query.watch().map((rows) => rows.map(_sessionFromRow).toList());
  }

  Future<List<AttendanceSession>> getSessionsForCourse(String courseId) async {
    final query = select(attendanceSessions)
      ..where((t) => t.courseId.equals(courseId))
      ..orderBy([(t) => OrderingTerm.desc(t.classNumber)]);
    final rows = await query.get();
    return rows.map(_sessionFromRow).toList();
  }

  Future<List<AttendanceRecord>> getRecordsForSession(String sessionId) async {
    final query = select(attendanceRecords)..where((t) => t.attendanceSessionId.equals(sessionId));
    final rows = await query.get();
    return rows.map(_recordFromRow).toList();
  }

  Future<List<AttendanceRecord>> getAllRecordsForCourse(String courseId) async {
    final sessionQuery = select(attendanceSessions)..where((t) => t.courseId.equals(courseId));
    final sessionsList = await sessionQuery.get();
    if (sessionsList.isEmpty) return [];

    final sessionIds = sessionsList.map((s) => s.id).toList();
    final query = select(attendanceRecords)..where((t) => t.attendanceSessionId.isIn(sessionIds));
    final rows = await query.get();
    return rows.map(_recordFromRow).toList();
  }

  /// Save attendance session and records atomically in a transaction
  Future<void> saveAttendanceSessionTransaction({
    required AttendanceSession session,
    required List<AttendanceRecord> recordsList,
  }) async {
    await transaction(() async {
      await into(attendanceSessions).insertOnConflictUpdate(
        AttendanceSessionRow(
          id: session.id,
          courseId: session.courseId,
          classNumber: session.classNumber,
          date: session.date,
          topic: session.topic,
          createdAt: session.createdAt,
          synced: session.synced,
        ),
      );

      await batch((batch) {
        batch.insertAllOnConflictUpdate(
          attendanceRecords,
          recordsList.map((r) => AttendanceRecordRow(
            id: r.id,
            attendanceSessionId: r.attendanceSessionId,
            studentId: r.studentId,
            status: r.status.toValue(),
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
            synced: r.synced,
          )).toList(),
        );
      });
    });
  }

  // --- MAP MAPPERS ---
  Course _courseFromRow(CourseRow row) {
    return Course(
      id: row.id,
      lecturerId: row.lecturerId,
      courseCode: row.courseCode,
      courseTitle: row.courseTitle,
      department: row.department,
      level: row.level,
      semester: row.semester,
      academicSession: row.academicSession,
      expectedClasses: row.expectedClasses,
      status: CourseStatus.fromValue(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      synced: row.synced,
    );
  }

  Student _studentFromRow(StudentRow row) {
    return Student(
      id: row.id,
      courseId: row.courseId,
      name: row.name,
      matricNumber: row.matricNumber,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      synced: row.synced,
    );
  }

  AttendanceSession _sessionFromRow(AttendanceSessionRow row) {
    return AttendanceSession(
      id: row.id,
      courseId: row.courseId,
      classNumber: row.classNumber,
      date: row.date,
      topic: row.topic,
      createdAt: row.createdAt,
      synced: row.synced,
    );
  }

  AttendanceRecord _recordFromRow(AttendanceRecordRow row) {
    return AttendanceRecord(
      id: row.id,
      attendanceSessionId: row.attendanceSessionId,
      studentId: row.studentId,
      status: AttendanceStatus.fromValue(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      synced: row.synced,
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'lecturer_attendance.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
