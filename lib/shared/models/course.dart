import 'package:flutter/foundation.dart';

enum CourseStatus {
  active,
  archived,
  completed;

  String toValue() => name;
  static CourseStatus fromValue(String? val) {
    return CourseStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => CourseStatus.active,
    );
  }
}

@immutable
class Course {
  final String id;
  final String lecturerId;
  final String courseCode;
  final String courseTitle;
  final String department;
  final String level;
  final String semester;
  final String academicSession;
  final int expectedClasses;
  final CourseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  const Course({
    required this.id,
    required this.lecturerId,
    required this.courseCode,
    required this.courseTitle,
    required this.department,
    required this.level,
    required this.semester,
    required this.academicSession,
    this.expectedClasses = 15,
    this.status = CourseStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  Course copyWith({
    String? id,
    String? lecturerId,
    String? courseCode,
    String? courseTitle,
    String? department,
    String? level,
    String? semester,
    String? academicSession,
    int? expectedClasses,
    CourseStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Course(
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
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lecturerId': lecturerId,
      'courseCode': courseCode,
      'courseTitle': courseTitle,
      'department': department,
      'level': level,
      'semester': semester,
      'academicSession': academicSession,
      'expectedClasses': expectedClasses,
      'status': status.toValue(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      lecturerId: map['lecturerId'] as String,
      courseCode: map['courseCode'] as String? ?? '',
      courseTitle: map['courseTitle'] as String? ?? '',
      department: map['department'] as String? ?? '',
      level: map['level'] as String? ?? '',
      semester: map['semester'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      expectedClasses: map['expectedClasses'] as int? ?? 15,
      status: CourseStatus.fromValue(map['status'] as String?),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      synced: map['synced'] as bool? ?? false,
    );
  }
}
