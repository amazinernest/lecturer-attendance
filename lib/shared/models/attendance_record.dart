import 'package:flutter/foundation.dart';

enum AttendanceStatus {
  present,
  absent;

  String toValue() => name;
  static AttendanceStatus fromValue(String? val) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => AttendanceStatus.absent,
    );
  }
}

@immutable
class AttendanceRecord {
  final String id;
  final String attendanceSessionId;
  final String studentId;
  final AttendanceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  const AttendanceRecord({
    required this.id,
    required this.attendanceSessionId,
    required this.studentId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  AttendanceRecord copyWith({
    String? id,
    String? attendanceSessionId,
    String? studentId,
    AttendanceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      attendanceSessionId: attendanceSessionId ?? this.attendanceSessionId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'attendanceSessionId': attendanceSessionId,
      'studentId': studentId,
      'status': status.toValue(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as String,
      attendanceSessionId: map['attendanceSessionId'] as String,
      studentId: map['studentId'] as String,
      status: AttendanceStatus.fromValue(map['status'] as String?),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      synced: map['synced'] as bool? ?? false,
    );
  }
}
