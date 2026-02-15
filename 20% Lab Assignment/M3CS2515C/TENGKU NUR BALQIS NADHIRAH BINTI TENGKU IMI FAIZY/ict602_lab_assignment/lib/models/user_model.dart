/// User model class representing a user in the system
/// Supports three roles: admin, lecturer, student
class UserModel {
  final String email;
  final String name;
  final String role;
  final double test;
  final double assignment;
  final double project;

  UserModel({
    required this.email,
    this.name = '',
    required this.role,
    this.test = 0,
    this.assignment = 0,
    this.project = 0,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'student',
      test: (map['test'] ?? 0).toDouble(),
      assignment: (map['assignment'] ?? 0).toDouble(),
      project: (map['project'] ?? 0).toDouble(),
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'test': test,
      'assignment': assignment,
      'project': project,
    };
  }

  /// Calculate total carry marks (Test 20% + Assignment 10% + Project 20% = 50%)
  double get totalCarryMark => test + assignment + project;

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is lecturer
  bool get isLecturer => role == 'lecturer';

  /// Check if user is student
  bool get isStudent => role == 'student';
}
