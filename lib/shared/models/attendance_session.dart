import 'package:flutter/foundation.dart';

@immutable
class AttendanceSession {
  final String id;
  final String courseId;
  final int classNumber;
  final DateTime date;
  final String topic;
  final DateTime createdAt;
  final bool synced;

  const AttendanceSession({
    required this.id,
    required this.courseId,
    required this.classNumber,
    required this.date,
    required this.topic,
    required this.createdAt,
    this.synced = false,
  });

  AttendanceSession copyWith({
    String? id,
    String? courseId,
    int? classNumber,
    DateTime? date,
    String? topic,
    DateTime? createdAt,
    bool? synced,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      classNumber: classNumber ?? this.classNumber,
      date: date ?? this.date,
      topic: topic ?? this.topic,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'classNumber': classNumber,
      'date': date.toIso8601String(),
      'topic': topic,
      'createdAt': createdAt.toIso8601String(),
      'synced': synced,
    };
  }

  factory AttendanceSession.fromMap(Map<String, dynamic> map) {
    return AttendanceSession(
      id: map['id'] as String,
      courseId: map['courseId'] as String,
      classNumber: map['classNumber'] as int? ?? 1,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      topic: map['topic'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      synced: map['synced'] as bool? ?? false,
    );
  }
}
