import 'package:flutter/foundation.dart';

@immutable
class LecturerUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;

  const LecturerUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
  });

  LecturerUser copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return LecturerUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LecturerUser.fromMap(Map<String, dynamic> map) {
    return LecturerUser(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Dr. Lecturer',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
