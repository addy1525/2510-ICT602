import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Service class for database operations with Firestore
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Login user by checking email and password in Firestore
  /// Returns UserModel if successful, null if failed
  Future<UserModel?> loginUser(String email, String password) async {
    try {
      // Query users collection for matching email
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // User found, return UserModel
        Map<String, dynamic> userData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        return UserModel.fromMap(userData);
      }
      return null; // Login failed
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  /// Get all students from Firestore
  Future<List<UserModel>> getStudents() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting students: $e');
      return [];
    }
  }

  /// Update student marks in Firestore
  Future<bool> updateStudentMarks(
    String email,
    double test,
    double assignment,
    double project,
  ) async {
    try {
      // Find the student document by email
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update the document
        await querySnapshot.docs.first.reference.update({
          'test': test,
          'assignment': assignment,
          'project': project,
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating marks: $e');
      return false;
    }
  }

  /// Get specific student marks by email
  Future<UserModel?> getStudentMarks(String email) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        Map<String, dynamic> data =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting student marks: $e');
      return null;
    }
  }
}
