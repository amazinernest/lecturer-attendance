// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, UserRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _photoUrlMeta =
      const VerificationMeta('photoUrl');
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
      'photo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, email, photoUrl, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<UserRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('photo_url')) {
      context.handle(_photoUrlMeta,
          photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      photoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_url']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class UserRow extends DataClass implements Insertable<UserRow> {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  const UserRow(
      {required this.id,
      required this.name,
      required this.email,
      this.photoUrl,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      email: Value(email),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      createdAt: Value(createdAt),
    );
  }

  factory UserRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserRow copyWith(
          {String? id,
          String? name,
          String? email,
          Value<String?> photoUrl = const Value.absent(),
          DateTime? createdAt}) =>
      UserRow(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
        createdAt: createdAt ?? this.createdAt,
      );
  UserRow copyWithCompanion(UsersCompanion data) {
    return UserRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, email, photoUrl, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.photoUrl == this.photoUrl &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<UserRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> email;
  final Value<String?> photoUrl;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String name,
    required String email,
    this.photoUrl = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        email = Value(email),
        createdAt = Value(createdAt);
  static Insertable<UserRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? photoUrl,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? email,
      Value<String?>? photoUrl,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CoursesTable extends Courses with TableInfo<$CoursesTable, CourseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lecturerIdMeta =
      const VerificationMeta('lecturerId');
  @override
  late final GeneratedColumn<String> lecturerId = GeneratedColumn<String>(
      'lecturer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _courseCodeMeta =
      const VerificationMeta('courseCode');
  @override
  late final GeneratedColumn<String> courseCode = GeneratedColumn<String>(
      'course_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _courseTitleMeta =
      const VerificationMeta('courseTitle');
  @override
  late final GeneratedColumn<String> courseTitle = GeneratedColumn<String>(
      'course_title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _departmentMeta =
      const VerificationMeta('department');
  @override
  late final GeneratedColumn<String> department = GeneratedColumn<String>(
      'department', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
      'level', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _semesterMeta =
      const VerificationMeta('semester');
  @override
  late final GeneratedColumn<String> semester = GeneratedColumn<String>(
      'semester', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _academicSessionMeta =
      const VerificationMeta('academicSession');
  @override
  late final GeneratedColumn<String> academicSession = GeneratedColumn<String>(
      'academic_session', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expectedClassesMeta =
      const VerificationMeta('expectedClasses');
  @override
  late final GeneratedColumn<int> expectedClasses = GeneratedColumn<int>(
      'expected_classes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(15));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        lecturerId,
        courseCode,
        courseTitle,
        department,
        level,
        semester,
        academicSession,
        expectedClasses,
        status,
        createdAt,
        updatedAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'courses';
  @override
  VerificationContext validateIntegrity(Insertable<CourseRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lecturer_id')) {
      context.handle(
          _lecturerIdMeta,
          lecturerId.isAcceptableOrUnknown(
              data['lecturer_id']!, _lecturerIdMeta));
    } else if (isInserting) {
      context.missing(_lecturerIdMeta);
    }
    if (data.containsKey('course_code')) {
      context.handle(
          _courseCodeMeta,
          courseCode.isAcceptableOrUnknown(
              data['course_code']!, _courseCodeMeta));
    } else if (isInserting) {
      context.missing(_courseCodeMeta);
    }
    if (data.containsKey('course_title')) {
      context.handle(
          _courseTitleMeta,
          courseTitle.isAcceptableOrUnknown(
              data['course_title']!, _courseTitleMeta));
    } else if (isInserting) {
      context.missing(_courseTitleMeta);
    }
    if (data.containsKey('department')) {
      context.handle(
          _departmentMeta,
          department.isAcceptableOrUnknown(
              data['department']!, _departmentMeta));
    } else if (isInserting) {
      context.missing(_departmentMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('semester')) {
      context.handle(_semesterMeta,
          semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta));
    } else if (isInserting) {
      context.missing(_semesterMeta);
    }
    if (data.containsKey('academic_session')) {
      context.handle(
          _academicSessionMeta,
          academicSession.isAcceptableOrUnknown(
              data['academic_session']!, _academicSessionMeta));
    } else if (isInserting) {
      context.missing(_academicSessionMeta);
    }
    if (data.containsKey('expected_classes')) {
      context.handle(
          _expectedClassesMeta,
          expectedClasses.isAcceptableOrUnknown(
              data['expected_classes']!, _expectedClassesMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      lecturerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lecturer_id'])!,
      courseCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}course_code'])!,
      courseTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}course_title'])!,
      department: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}department'])!,
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level'])!,
      semester: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}semester'])!,
      academicSession: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}academic_session'])!,
      expectedClasses: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expected_classes'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $CoursesTable createAlias(String alias) {
    return $CoursesTable(attachedDatabase, alias);
  }
}

class CourseRow extends DataClass implements Insertable<CourseRow> {
  final String id;
  final String lecturerId;
  final String courseCode;
  final String courseTitle;
  final String department;
  final String level;
  final String semester;
  final String academicSession;
  final int expectedClasses;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
  const CourseRow(
      {required this.id,
      required this.lecturerId,
      required this.courseCode,
      required this.courseTitle,
      required this.department,
      required this.level,
      required this.semester,
      required this.academicSession,
      required this.expectedClasses,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lecturer_id'] = Variable<String>(lecturerId);
    map['course_code'] = Variable<String>(courseCode);
    map['course_title'] = Variable<String>(courseTitle);
    map['department'] = Variable<String>(department);
    map['level'] = Variable<String>(level);
    map['semester'] = Variable<String>(semester);
    map['academic_session'] = Variable<String>(academicSession);
    map['expected_classes'] = Variable<int>(expectedClasses);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  CoursesCompanion toCompanion(bool nullToAbsent) {
    return CoursesCompanion(
      id: Value(id),
      lecturerId: Value(lecturerId),
      courseCode: Value(courseCode),
      courseTitle: Value(courseTitle),
      department: Value(department),
      level: Value(level),
      semester: Value(semester),
      academicSession: Value(academicSession),
      expectedClasses: Value(expectedClasses),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      synced: Value(synced),
    );
  }

  factory CourseRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseRow(
      id: serializer.fromJson<String>(json['id']),
      lecturerId: serializer.fromJson<String>(json['lecturerId']),
      courseCode: serializer.fromJson<String>(json['courseCode']),
      courseTitle: serializer.fromJson<String>(json['courseTitle']),
      department: serializer.fromJson<String>(json['department']),
      level: serializer.fromJson<String>(json['level']),
      semester: serializer.fromJson<String>(json['semester']),
      academicSession: serializer.fromJson<String>(json['academicSession']),
      expectedClasses: serializer.fromJson<int>(json['expectedClasses']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lecturerId': serializer.toJson<String>(lecturerId),
      'courseCode': serializer.toJson<String>(courseCode),
      'courseTitle': serializer.toJson<String>(courseTitle),
      'department': serializer.toJson<String>(department),
      'level': serializer.toJson<String>(level),
      'semester': serializer.toJson<String>(semester),
      'academicSession': serializer.toJson<String>(academicSession),
      'expectedClasses': serializer.toJson<int>(expectedClasses),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  CourseRow copyWith(
          {String? id,
          String? lecturerId,
          String? courseCode,
          String? courseTitle,
          String? department,
          String? level,
          String? semester,
          String? academicSession,
          int? expectedClasses,
          String? status,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? synced}) =>
      CourseRow(
        id: id ?? this.id,
        lecturerId: lecturerId ?? this.lecturerId,
        courseCode: courseCode ?? this.courseCode,
        courseTitle: courseTitle ?? this.courseTitle,
        department: department ?? this.department,
        level: level ?? this.level,
        semester: semester ?? this.semester,
        academicSession: academicSession ?? this.academicSession,
        expectedClasses: expectedClasses ?? this.expectedClasses,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        synced: synced ?? this.synced,
      );
  CourseRow copyWithCompanion(CoursesCompanion data) {
    return CourseRow(
      id: data.id.present ? data.id.value : this.id,
      lecturerId:
          data.lecturerId.present ? data.lecturerId.value : this.lecturerId,
      courseCode:
          data.courseCode.present ? data.courseCode.value : this.courseCode,
      courseTitle:
          data.courseTitle.present ? data.courseTitle.value : this.courseTitle,
      department:
          data.department.present ? data.department.value : this.department,
      level: data.level.present ? data.level.value : this.level,
      semester: data.semester.present ? data.semester.value : this.semester,
      academicSession: data.academicSession.present
          ? data.academicSession.value
          : this.academicSession,
      expectedClasses: data.expectedClasses.present
          ? data.expectedClasses.value
          : this.expectedClasses,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseRow(')
          ..write('id: $id, ')
          ..write('lecturerId: $lecturerId, ')
          ..write('courseCode: $courseCode, ')
          ..write('courseTitle: $courseTitle, ')
          ..write('department: $department, ')
          ..write('level: $level, ')
          ..write('semester: $semester, ')
          ..write('academicSession: $academicSession, ')
          ..write('expectedClasses: $expectedClasses, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      lecturerId,
      courseCode,
      courseTitle,
      department,
      level,
      semester,
      academicSession,
      expectedClasses,
      status,
      createdAt,
      updatedAt,
      synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseRow &&
          other.id == this.id &&
          other.lecturerId == this.lecturerId &&
          other.courseCode == this.courseCode &&
          other.courseTitle == this.courseTitle &&
          other.department == this.department &&
          other.level == this.level &&
          other.semester == this.semester &&
          other.academicSession == this.academicSession &&
          other.expectedClasses == this.expectedClasses &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.synced == this.synced);
}

class CoursesCompanion extends UpdateCompanion<CourseRow> {
  final Value<String> id;
  final Value<String> lecturerId;
  final Value<String> courseCode;
  final Value<String> courseTitle;
  final Value<String> department;
  final Value<String> level;
  final Value<String> semester;
  final Value<String> academicSession;
  final Value<int> expectedClasses;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const CoursesCompanion({
    this.id = const Value.absent(),
    this.lecturerId = const Value.absent(),
    this.courseCode = const Value.absent(),
    this.courseTitle = const Value.absent(),
    this.department = const Value.absent(),
    this.level = const Value.absent(),
    this.semester = const Value.absent(),
    this.academicSession = const Value.absent(),
    this.expectedClasses = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoursesCompanion.insert({
    required String id,
    required String lecturerId,
    required String courseCode,
    required String courseTitle,
    required String department,
    required String level,
    required String semester,
    required String academicSession,
    this.expectedClasses = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        lecturerId = Value(lecturerId),
        courseCode = Value(courseCode),
        courseTitle = Value(courseTitle),
        department = Value(department),
        level = Value(level),
        semester = Value(semester),
        academicSession = Value(academicSession),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CourseRow> custom({
    Expression<String>? id,
    Expression<String>? lecturerId,
    Expression<String>? courseCode,
    Expression<String>? courseTitle,
    Expression<String>? department,
    Expression<String>? level,
    Expression<String>? semester,
    Expression<String>? academicSession,
    Expression<int>? expectedClasses,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lecturerId != null) 'lecturer_id': lecturerId,
      if (courseCode != null) 'course_code': courseCode,
      if (courseTitle != null) 'course_title': courseTitle,
      if (department != null) 'department': department,
      if (level != null) 'level': level,
      if (semester != null) 'semester': semester,
      if (academicSession != null) 'academic_session': academicSession,
      if (expectedClasses != null) 'expected_classes': expectedClasses,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoursesCompanion copyWith(
      {Value<String>? id,
      Value<String>? lecturerId,
      Value<String>? courseCode,
      Value<String>? courseTitle,
      Value<String>? department,
      Value<String>? level,
      Value<String>? semester,
      Value<String>? academicSession,
      Value<int>? expectedClasses,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return CoursesCompanion(
      id: id ?? this.id,
      lecturerId: lecturerId ?? this.lecturerId,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      department: department ?? this.department,
      level: level ?? this.level,
      semester: semester ?? this.semester,
      academicSession: academicSession ?? this.academicSession,
      expectedClasses: expectedClasses ?? this.expectedClasses,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lecturerId.present) {
      map['lecturer_id'] = Variable<String>(lecturerId.value);
    }
    if (courseCode.present) {
      map['course_code'] = Variable<String>(courseCode.value);
    }
    if (courseTitle.present) {
      map['course_title'] = Variable<String>(courseTitle.value);
    }
    if (department.present) {
      map['department'] = Variable<String>(department.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (semester.present) {
      map['semester'] = Variable<String>(semester.value);
    }
    if (academicSession.present) {
      map['academic_session'] = Variable<String>(academicSession.value);
    }
    if (expectedClasses.present) {
      map['expected_classes'] = Variable<int>(expectedClasses.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoursesCompanion(')
          ..write('id: $id, ')
          ..write('lecturerId: $lecturerId, ')
          ..write('courseCode: $courseCode, ')
          ..write('courseTitle: $courseTitle, ')
          ..write('department: $department, ')
          ..write('level: $level, ')
          ..write('semester: $semester, ')
          ..write('academicSession: $academicSession, ')
          ..write('expectedClasses: $expectedClasses, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudentsTable extends Students
    with TableInfo<$StudentsTable, StudentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _courseIdMeta =
      const VerificationMeta('courseId');
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
      'course_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _matricNumberMeta =
      const VerificationMeta('matricNumber');
  @override
  late final GeneratedColumn<String> matricNumber = GeneratedColumn<String>(
      'matric_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, courseId, name, matricNumber, createdAt, updatedAt, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'students';
  @override
  VerificationContext validateIntegrity(Insertable<StudentRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(_courseIdMeta,
          courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta));
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('matric_number')) {
      context.handle(
          _matricNumberMeta,
          matricNumber.isAcceptableOrUnknown(
              data['matric_number']!, _matricNumberMeta));
    } else if (isInserting) {
      context.missing(_matricNumberMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      courseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}course_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      matricNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}matric_number'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $StudentsTable createAlias(String alias) {
    return $StudentsTable(attachedDatabase, alias);
  }
}

class StudentRow extends DataClass implements Insertable<StudentRow> {
  final String id;
  final String courseId;
  final String name;
  final String matricNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
  const StudentRow(
      {required this.id,
      required this.courseId,
      required this.name,
      required this.matricNumber,
      required this.createdAt,
      required this.updatedAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['course_id'] = Variable<String>(courseId);
    map['name'] = Variable<String>(name);
    map['matric_number'] = Variable<String>(matricNumber);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  StudentsCompanion toCompanion(bool nullToAbsent) {
    return StudentsCompanion(
      id: Value(id),
      courseId: Value(courseId),
      name: Value(name),
      matricNumber: Value(matricNumber),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      synced: Value(synced),
    );
  }

  factory StudentRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentRow(
      id: serializer.fromJson<String>(json['id']),
      courseId: serializer.fromJson<String>(json['courseId']),
      name: serializer.fromJson<String>(json['name']),
      matricNumber: serializer.fromJson<String>(json['matricNumber']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'courseId': serializer.toJson<String>(courseId),
      'name': serializer.toJson<String>(name),
      'matricNumber': serializer.toJson<String>(matricNumber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  StudentRow copyWith(
          {String? id,
          String? courseId,
          String? name,
          String? matricNumber,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? synced}) =>
      StudentRow(
        id: id ?? this.id,
        courseId: courseId ?? this.courseId,
        name: name ?? this.name,
        matricNumber: matricNumber ?? this.matricNumber,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        synced: synced ?? this.synced,
      );
  StudentRow copyWithCompanion(StudentsCompanion data) {
    return StudentRow(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      name: data.name.present ? data.name.value : this.name,
      matricNumber: data.matricNumber.present
          ? data.matricNumber.value
          : this.matricNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentRow(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('name: $name, ')
          ..write('matricNumber: $matricNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, courseId, name, matricNumber, createdAt, updatedAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentRow &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.name == this.name &&
          other.matricNumber == this.matricNumber &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.synced == this.synced);
}

class StudentsCompanion extends UpdateCompanion<StudentRow> {
  final Value<String> id;
  final Value<String> courseId;
  final Value<String> name;
  final Value<String> matricNumber;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const StudentsCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.name = const Value.absent(),
    this.matricNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudentsCompanion.insert({
    required String id,
    required String courseId,
    required String name,
    required String matricNumber,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        courseId = Value(courseId),
        name = Value(name),
        matricNumber = Value(matricNumber),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<StudentRow> custom({
    Expression<String>? id,
    Expression<String>? courseId,
    Expression<String>? name,
    Expression<String>? matricNumber,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (name != null) 'name': name,
      if (matricNumber != null) 'matric_number': matricNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? courseId,
      Value<String>? name,
      Value<String>? matricNumber,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return StudentsCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      matricNumber: matricNumber ?? this.matricNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (matricNumber.present) {
      map['matric_number'] = Variable<String>(matricNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentsCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('name: $name, ')
          ..write('matricNumber: $matricNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceSessionsTable extends AttendanceSessions
    with TableInfo<$AttendanceSessionsTable, AttendanceSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _courseIdMeta =
      const VerificationMeta('courseId');
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
      'course_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _classNumberMeta =
      const VerificationMeta('classNumber');
  @override
  late final GeneratedColumn<int> classNumber = GeneratedColumn<int>(
      'class_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
      'topic', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, courseId, classNumber, date, topic, createdAt, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_sessions';
  @override
  VerificationContext validateIntegrity(
      Insertable<AttendanceSessionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(_courseIdMeta,
          courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta));
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('class_number')) {
      context.handle(
          _classNumberMeta,
          classNumber.isAcceptableOrUnknown(
              data['class_number']!, _classNumberMeta));
    } else if (isInserting) {
      context.missing(_classNumberMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('topic')) {
      context.handle(
          _topicMeta, topic.isAcceptableOrUnknown(data['topic']!, _topicMeta));
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceSessionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      courseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}course_id'])!,
      classNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}class_number'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      topic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}topic'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $AttendanceSessionsTable createAlias(String alias) {
    return $AttendanceSessionsTable(attachedDatabase, alias);
  }
}

class AttendanceSessionRow extends DataClass
    implements Insertable<AttendanceSessionRow> {
  final String id;
  final String courseId;
  final int classNumber;
  final DateTime date;
  final String topic;
  final DateTime createdAt;
  final bool synced;
  const AttendanceSessionRow(
      {required this.id,
      required this.courseId,
      required this.classNumber,
      required this.date,
      required this.topic,
      required this.createdAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['course_id'] = Variable<String>(courseId);
    map['class_number'] = Variable<int>(classNumber);
    map['date'] = Variable<DateTime>(date);
    map['topic'] = Variable<String>(topic);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  AttendanceSessionsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceSessionsCompanion(
      id: Value(id),
      courseId: Value(courseId),
      classNumber: Value(classNumber),
      date: Value(date),
      topic: Value(topic),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory AttendanceSessionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceSessionRow(
      id: serializer.fromJson<String>(json['id']),
      courseId: serializer.fromJson<String>(json['courseId']),
      classNumber: serializer.fromJson<int>(json['classNumber']),
      date: serializer.fromJson<DateTime>(json['date']),
      topic: serializer.fromJson<String>(json['topic']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'courseId': serializer.toJson<String>(courseId),
      'classNumber': serializer.toJson<int>(classNumber),
      'date': serializer.toJson<DateTime>(date),
      'topic': serializer.toJson<String>(topic),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  AttendanceSessionRow copyWith(
          {String? id,
          String? courseId,
          int? classNumber,
          DateTime? date,
          String? topic,
          DateTime? createdAt,
          bool? synced}) =>
      AttendanceSessionRow(
        id: id ?? this.id,
        courseId: courseId ?? this.courseId,
        classNumber: classNumber ?? this.classNumber,
        date: date ?? this.date,
        topic: topic ?? this.topic,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );
  AttendanceSessionRow copyWithCompanion(AttendanceSessionsCompanion data) {
    return AttendanceSessionRow(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      classNumber:
          data.classNumber.present ? data.classNumber.value : this.classNumber,
      date: data.date.present ? data.date.value : this.date,
      topic: data.topic.present ? data.topic.value : this.topic,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceSessionRow(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('classNumber: $classNumber, ')
          ..write('date: $date, ')
          ..write('topic: $topic, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, courseId, classNumber, date, topic, createdAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceSessionRow &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.classNumber == this.classNumber &&
          other.date == this.date &&
          other.topic == this.topic &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class AttendanceSessionsCompanion
    extends UpdateCompanion<AttendanceSessionRow> {
  final Value<String> id;
  final Value<String> courseId;
  final Value<int> classNumber;
  final Value<DateTime> date;
  final Value<String> topic;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const AttendanceSessionsCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.classNumber = const Value.absent(),
    this.date = const Value.absent(),
    this.topic = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceSessionsCompanion.insert({
    required String id,
    required String courseId,
    required int classNumber,
    required DateTime date,
    required String topic,
    required DateTime createdAt,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        courseId = Value(courseId),
        classNumber = Value(classNumber),
        date = Value(date),
        topic = Value(topic),
        createdAt = Value(createdAt);
  static Insertable<AttendanceSessionRow> custom({
    Expression<String>? id,
    Expression<String>? courseId,
    Expression<int>? classNumber,
    Expression<DateTime>? date,
    Expression<String>? topic,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (classNumber != null) 'class_number': classNumber,
      if (date != null) 'date': date,
      if (topic != null) 'topic': topic,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? courseId,
      Value<int>? classNumber,
      Value<DateTime>? date,
      Value<String>? topic,
      Value<DateTime>? createdAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return AttendanceSessionsCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      classNumber: classNumber ?? this.classNumber,
      date: date ?? this.date,
      topic: topic ?? this.topic,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (classNumber.present) {
      map['class_number'] = Variable<int>(classNumber.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceSessionsCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('classNumber: $classNumber, ')
          ..write('date: $date, ')
          ..write('topic: $topic, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceRecordsTable extends AttendanceRecords
    with TableInfo<$AttendanceRecordsTable, AttendanceRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attendanceSessionIdMeta =
      const VerificationMeta('attendanceSessionId');
  @override
  late final GeneratedColumn<String> attendanceSessionId =
      GeneratedColumn<String>('attendance_session_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
      'student_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        attendanceSessionId,
        studentId,
        status,
        createdAt,
        updatedAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_records';
  @override
  VerificationContext validateIntegrity(
      Insertable<AttendanceRecordRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('attendance_session_id')) {
      context.handle(
          _attendanceSessionIdMeta,
          attendanceSessionId.isAcceptableOrUnknown(
              data['attendance_session_id']!, _attendanceSessionIdMeta));
    } else if (isInserting) {
      context.missing(_attendanceSessionIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceRecordRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      attendanceSessionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}attendance_session_id'])!,
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $AttendanceRecordsTable createAlias(String alias) {
    return $AttendanceRecordsTable(attachedDatabase, alias);
  }
}

class AttendanceRecordRow extends DataClass
    implements Insertable<AttendanceRecordRow> {
  final String id;
  final String attendanceSessionId;
  final String studentId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
  const AttendanceRecordRow(
      {required this.id,
      required this.attendanceSessionId,
      required this.studentId,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['attendance_session_id'] = Variable<String>(attendanceSessionId);
    map['student_id'] = Variable<String>(studentId);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  AttendanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceRecordsCompanion(
      id: Value(id),
      attendanceSessionId: Value(attendanceSessionId),
      studentId: Value(studentId),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      synced: Value(synced),
    );
  }

  factory AttendanceRecordRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceRecordRow(
      id: serializer.fromJson<String>(json['id']),
      attendanceSessionId:
          serializer.fromJson<String>(json['attendanceSessionId']),
      studentId: serializer.fromJson<String>(json['studentId']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'attendanceSessionId': serializer.toJson<String>(attendanceSessionId),
      'studentId': serializer.toJson<String>(studentId),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  AttendanceRecordRow copyWith(
          {String? id,
          String? attendanceSessionId,
          String? studentId,
          String? status,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? synced}) =>
      AttendanceRecordRow(
        id: id ?? this.id,
        attendanceSessionId: attendanceSessionId ?? this.attendanceSessionId,
        studentId: studentId ?? this.studentId,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        synced: synced ?? this.synced,
      );
  AttendanceRecordRow copyWithCompanion(AttendanceRecordsCompanion data) {
    return AttendanceRecordRow(
      id: data.id.present ? data.id.value : this.id,
      attendanceSessionId: data.attendanceSessionId.present
          ? data.attendanceSessionId.value
          : this.attendanceSessionId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecordRow(')
          ..write('id: $id, ')
          ..write('attendanceSessionId: $attendanceSessionId, ')
          ..write('studentId: $studentId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, attendanceSessionId, studentId, status, createdAt, updatedAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceRecordRow &&
          other.id == this.id &&
          other.attendanceSessionId == this.attendanceSessionId &&
          other.studentId == this.studentId &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.synced == this.synced);
}

class AttendanceRecordsCompanion extends UpdateCompanion<AttendanceRecordRow> {
  final Value<String> id;
  final Value<String> attendanceSessionId;
  final Value<String> studentId;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const AttendanceRecordsCompanion({
    this.id = const Value.absent(),
    this.attendanceSessionId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceRecordsCompanion.insert({
    required String id,
    required String attendanceSessionId,
    required String studentId,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        attendanceSessionId = Value(attendanceSessionId),
        studentId = Value(studentId),
        status = Value(status),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<AttendanceRecordRow> custom({
    Expression<String>? id,
    Expression<String>? attendanceSessionId,
    Expression<String>? studentId,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (attendanceSessionId != null)
        'attendance_session_id': attendanceSessionId,
      if (studentId != null) 'student_id': studentId,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceRecordsCompanion copyWith(
      {Value<String>? id,
      Value<String>? attendanceSessionId,
      Value<String>? studentId,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return AttendanceRecordsCompanion(
      id: id ?? this.id,
      attendanceSessionId: attendanceSessionId ?? this.attendanceSessionId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (attendanceSessionId.present) {
      map['attendance_session_id'] =
          Variable<String>(attendanceSessionId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecordsCompanion(')
          ..write('id: $id, ')
          ..write('attendanceSessionId: $attendanceSessionId, ')
          ..write('studentId: $studentId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $CoursesTable courses = $CoursesTable(this);
  late final $StudentsTable students = $StudentsTable(this);
  late final $AttendanceSessionsTable attendanceSessions =
      $AttendanceSessionsTable(this);
  late final $AttendanceRecordsTable attendanceRecords =
      $AttendanceRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [users, courses, students, attendanceSessions, attendanceRecords];
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  required String name,
  required String email,
  Value<String?> photoUrl,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> email,
  Value<String?> photoUrl,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    UserRow,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (UserRow, BaseReferences<_$AppDatabase, $UsersTable, UserRow>),
    UserRow,
    PrefetchHooks Function()> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String?> photoUrl = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            name: name,
            email: email,
            photoUrl: photoUrl,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String email,
            Value<String?> photoUrl = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            name: name,
            email: email,
            photoUrl: photoUrl,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    UserRow,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (UserRow, BaseReferences<_$AppDatabase, $UsersTable, UserRow>),
    UserRow,
    PrefetchHooks Function()>;
typedef $$CoursesTableCreateCompanionBuilder = CoursesCompanion Function({
  required String id,
  required String lecturerId,
  required String courseCode,
  required String courseTitle,
  required String department,
  required String level,
  required String semester,
  required String academicSession,
  Value<int> expectedClasses,
  Value<String> status,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$CoursesTableUpdateCompanionBuilder = CoursesCompanion Function({
  Value<String> id,
  Value<String> lecturerId,
  Value<String> courseCode,
  Value<String> courseTitle,
  Value<String> department,
  Value<String> level,
  Value<String> semester,
  Value<String> academicSession,
  Value<int> expectedClasses,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$CoursesTableFilterComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lecturerId => $composableBuilder(
      column: $table.lecturerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get courseCode => $composableBuilder(
      column: $table.courseCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get courseTitle => $composableBuilder(
      column: $table.courseTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get department => $composableBuilder(
      column: $table.department, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get semester => $composableBuilder(
      column: $table.semester, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get academicSession => $composableBuilder(
      column: $table.academicSession,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expectedClasses => $composableBuilder(
      column: $table.expectedClasses,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$CoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lecturerId => $composableBuilder(
      column: $table.lecturerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get courseCode => $composableBuilder(
      column: $table.courseCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get courseTitle => $composableBuilder(
      column: $table.courseTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get department => $composableBuilder(
      column: $table.department, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get semester => $composableBuilder(
      column: $table.semester, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get academicSession => $composableBuilder(
      column: $table.academicSession,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expectedClasses => $composableBuilder(
      column: $table.expectedClasses,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$CoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get lecturerId => $composableBuilder(
      column: $table.lecturerId, builder: (column) => column);

  GeneratedColumn<String> get courseCode => $composableBuilder(
      column: $table.courseCode, builder: (column) => column);

  GeneratedColumn<String> get courseTitle => $composableBuilder(
      column: $table.courseTitle, builder: (column) => column);

  GeneratedColumn<String> get department => $composableBuilder(
      column: $table.department, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get semester =>
      $composableBuilder(column: $table.semester, builder: (column) => column);

  GeneratedColumn<String> get academicSession => $composableBuilder(
      column: $table.academicSession, builder: (column) => column);

  GeneratedColumn<int> get expectedClasses => $composableBuilder(
      column: $table.expectedClasses, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$CoursesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CoursesTable,
    CourseRow,
    $$CoursesTableFilterComposer,
    $$CoursesTableOrderingComposer,
    $$CoursesTableAnnotationComposer,
    $$CoursesTableCreateCompanionBuilder,
    $$CoursesTableUpdateCompanionBuilder,
    (CourseRow, BaseReferences<_$AppDatabase, $CoursesTable, CourseRow>),
    CourseRow,
    PrefetchHooks Function()> {
  $$CoursesTableTableManager(_$AppDatabase db, $CoursesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoursesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> lecturerId = const Value.absent(),
            Value<String> courseCode = const Value.absent(),
            Value<String> courseTitle = const Value.absent(),
            Value<String> department = const Value.absent(),
            Value<String> level = const Value.absent(),
            Value<String> semester = const Value.absent(),
            Value<String> academicSession = const Value.absent(),
            Value<int> expectedClasses = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CoursesCompanion(
            id: id,
            lecturerId: lecturerId,
            courseCode: courseCode,
            courseTitle: courseTitle,
            department: department,
            level: level,
            semester: semester,
            academicSession: academicSession,
            expectedClasses: expectedClasses,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String lecturerId,
            required String courseCode,
            required String courseTitle,
            required String department,
            required String level,
            required String semester,
            required String academicSession,
            Value<int> expectedClasses = const Value.absent(),
            Value<String> status = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CoursesCompanion.insert(
            id: id,
            lecturerId: lecturerId,
            courseCode: courseCode,
            courseTitle: courseTitle,
            department: department,
            level: level,
            semester: semester,
            academicSession: academicSession,
            expectedClasses: expectedClasses,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CoursesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CoursesTable,
    CourseRow,
    $$CoursesTableFilterComposer,
    $$CoursesTableOrderingComposer,
    $$CoursesTableAnnotationComposer,
    $$CoursesTableCreateCompanionBuilder,
    $$CoursesTableUpdateCompanionBuilder,
    (CourseRow, BaseReferences<_$AppDatabase, $CoursesTable, CourseRow>),
    CourseRow,
    PrefetchHooks Function()>;
typedef $$StudentsTableCreateCompanionBuilder = StudentsCompanion Function({
  required String id,
  required String courseId,
  required String name,
  required String matricNumber,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$StudentsTableUpdateCompanionBuilder = StudentsCompanion Function({
  Value<String> id,
  Value<String> courseId,
  Value<String> name,
  Value<String> matricNumber,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$StudentsTableFilterComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get courseId => $composableBuilder(
      column: $table.courseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matricNumber => $composableBuilder(
      column: $table.matricNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$StudentsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get courseId => $composableBuilder(
      column: $table.courseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matricNumber => $composableBuilder(
      column: $table.matricNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$StudentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get matricNumber => $composableBuilder(
      column: $table.matricNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$StudentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StudentsTable,
    StudentRow,
    $$StudentsTableFilterComposer,
    $$StudentsTableOrderingComposer,
    $$StudentsTableAnnotationComposer,
    $$StudentsTableCreateCompanionBuilder,
    $$StudentsTableUpdateCompanionBuilder,
    (StudentRow, BaseReferences<_$AppDatabase, $StudentsTable, StudentRow>),
    StudentRow,
    PrefetchHooks Function()> {
  $$StudentsTableTableManager(_$AppDatabase db, $StudentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> courseId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> matricNumber = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StudentsCompanion(
            id: id,
            courseId: courseId,
            name: name,
            matricNumber: matricNumber,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String courseId,
            required String name,
            required String matricNumber,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StudentsCompanion.insert(
            id: id,
            courseId: courseId,
            name: name,
            matricNumber: matricNumber,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StudentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StudentsTable,
    StudentRow,
    $$StudentsTableFilterComposer,
    $$StudentsTableOrderingComposer,
    $$StudentsTableAnnotationComposer,
    $$StudentsTableCreateCompanionBuilder,
    $$StudentsTableUpdateCompanionBuilder,
    (StudentRow, BaseReferences<_$AppDatabase, $StudentsTable, StudentRow>),
    StudentRow,
    PrefetchHooks Function()>;
typedef $$AttendanceSessionsTableCreateCompanionBuilder
    = AttendanceSessionsCompanion Function({
  required String id,
  required String courseId,
  required int classNumber,
  required DateTime date,
  required String topic,
  required DateTime createdAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$AttendanceSessionsTableUpdateCompanionBuilder
    = AttendanceSessionsCompanion Function({
  Value<String> id,
  Value<String> courseId,
  Value<int> classNumber,
  Value<DateTime> date,
  Value<String> topic,
  Value<DateTime> createdAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$AttendanceSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceSessionsTable> {
  $$AttendanceSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get courseId => $composableBuilder(
      column: $table.courseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get classNumber => $composableBuilder(
      column: $table.classNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get topic => $composableBuilder(
      column: $table.topic, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$AttendanceSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceSessionsTable> {
  $$AttendanceSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get courseId => $composableBuilder(
      column: $table.courseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get classNumber => $composableBuilder(
      column: $table.classNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get topic => $composableBuilder(
      column: $table.topic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$AttendanceSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceSessionsTable> {
  $$AttendanceSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<int> get classNumber => $composableBuilder(
      column: $table.classNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$AttendanceSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttendanceSessionsTable,
    AttendanceSessionRow,
    $$AttendanceSessionsTableFilterComposer,
    $$AttendanceSessionsTableOrderingComposer,
    $$AttendanceSessionsTableAnnotationComposer,
    $$AttendanceSessionsTableCreateCompanionBuilder,
    $$AttendanceSessionsTableUpdateCompanionBuilder,
    (
      AttendanceSessionRow,
      BaseReferences<_$AppDatabase, $AttendanceSessionsTable,
          AttendanceSessionRow>
    ),
    AttendanceSessionRow,
    PrefetchHooks Function()> {
  $$AttendanceSessionsTableTableManager(
      _$AppDatabase db, $AttendanceSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceSessionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> courseId = const Value.absent(),
            Value<int> classNumber = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> topic = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendanceSessionsCompanion(
            id: id,
            courseId: courseId,
            classNumber: classNumber,
            date: date,
            topic: topic,
            createdAt: createdAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String courseId,
            required int classNumber,
            required DateTime date,
            required String topic,
            required DateTime createdAt,
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendanceSessionsCompanion.insert(
            id: id,
            courseId: courseId,
            classNumber: classNumber,
            date: date,
            topic: topic,
            createdAt: createdAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AttendanceSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AttendanceSessionsTable,
    AttendanceSessionRow,
    $$AttendanceSessionsTableFilterComposer,
    $$AttendanceSessionsTableOrderingComposer,
    $$AttendanceSessionsTableAnnotationComposer,
    $$AttendanceSessionsTableCreateCompanionBuilder,
    $$AttendanceSessionsTableUpdateCompanionBuilder,
    (
      AttendanceSessionRow,
      BaseReferences<_$AppDatabase, $AttendanceSessionsTable,
          AttendanceSessionRow>
    ),
    AttendanceSessionRow,
    PrefetchHooks Function()>;
typedef $$AttendanceRecordsTableCreateCompanionBuilder
    = AttendanceRecordsCompanion Function({
  required String id,
  required String attendanceSessionId,
  required String studentId,
  required String status,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$AttendanceRecordsTableUpdateCompanionBuilder
    = AttendanceRecordsCompanion Function({
  Value<String> id,
  Value<String> attendanceSessionId,
  Value<String> studentId,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$AttendanceRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attendanceSessionId => $composableBuilder(
      column: $table.attendanceSessionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$AttendanceRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attendanceSessionId => $composableBuilder(
      column: $table.attendanceSessionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$AttendanceRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get attendanceSessionId => $composableBuilder(
      column: $table.attendanceSessionId, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$AttendanceRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttendanceRecordsTable,
    AttendanceRecordRow,
    $$AttendanceRecordsTableFilterComposer,
    $$AttendanceRecordsTableOrderingComposer,
    $$AttendanceRecordsTableAnnotationComposer,
    $$AttendanceRecordsTableCreateCompanionBuilder,
    $$AttendanceRecordsTableUpdateCompanionBuilder,
    (
      AttendanceRecordRow,
      BaseReferences<_$AppDatabase, $AttendanceRecordsTable,
          AttendanceRecordRow>
    ),
    AttendanceRecordRow,
    PrefetchHooks Function()> {
  $$AttendanceRecordsTableTableManager(
      _$AppDatabase db, $AttendanceRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceRecordsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> attendanceSessionId = const Value.absent(),
            Value<String> studentId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendanceRecordsCompanion(
            id: id,
            attendanceSessionId: attendanceSessionId,
            studentId: studentId,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String attendanceSessionId,
            required String studentId,
            required String status,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendanceRecordsCompanion.insert(
            id: id,
            attendanceSessionId: attendanceSessionId,
            studentId: studentId,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AttendanceRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AttendanceRecordsTable,
    AttendanceRecordRow,
    $$AttendanceRecordsTableFilterComposer,
    $$AttendanceRecordsTableOrderingComposer,
    $$AttendanceRecordsTableAnnotationComposer,
    $$AttendanceRecordsTableCreateCompanionBuilder,
    $$AttendanceRecordsTableUpdateCompanionBuilder,
    (
      AttendanceRecordRow,
      BaseReferences<_$AppDatabase, $AttendanceRecordsTable,
          AttendanceRecordRow>
    ),
    AttendanceRecordRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$CoursesTableTableManager get courses =>
      $$CoursesTableTableManager(_db, _db.courses);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db, _db.students);
  $$AttendanceSessionsTableTableManager get attendanceSessions =>
      $$AttendanceSessionsTableTableManager(_db, _db.attendanceSessions);
  $$AttendanceRecordsTableTableManager get attendanceRecords =>
      $$AttendanceRecordsTableTableManager(_db, _db.attendanceRecords);
}
