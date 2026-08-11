import 'package:flutter/foundation.dart';

@immutable
class Student {
  final String id;
  final String courseId;
  final String name;
  final String matricNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  const Student({
    required this.id,
    required this.courseId,
    required this.name,
    required this.matricNumber,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  Student copyWith({
    String? id,
    String? courseId,
    String? name,
    String? matricNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Student(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      matricNumber: matricNumber ?? this.matricNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'name': name,
      'matricNumber': matricNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      courseId: map['courseId'] as String,
      name: map['name'] as String? ?? '',
      matricNumber: map['matricNumber'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      synced: map['synced'] as bool? ?? false,
    );
  }
}
