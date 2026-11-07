import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  student,
  staff;

  static UserRole fromName(String? name) =>
      name == 'staff' ? UserRole.staff : UserRole.student;

  String get label => this == UserRole.staff ? 'Staff' : 'Student';
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.department = '',
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final DateTime? createdAt;

  bool get isStaff => role == UserRole.staff;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final created = map['createdAt'];
    DateTime? parseCreatedAt(Object? value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return AppUser(
      uid: uid,
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      role: UserRole.fromName(map['role'] as String?),
      department: (map['department'] as String?) ?? '',
      createdAt: parseCreatedAt(created),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role.name,
        'department': department,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
