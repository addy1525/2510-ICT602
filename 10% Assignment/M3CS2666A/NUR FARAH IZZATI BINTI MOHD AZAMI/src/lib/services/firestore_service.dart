import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference students =
      FirebaseFirestore.instance.collection("students");

  Future<void> saveCarryMark(
      String studentId, double test, double assignment, double project) async {
    final double total = test + assignment + project;

    // Update markah + createdAt / updatedAt
    await students.doc(studentId).set({
      "marks": {
        "test": test,
        "assignment": assignment,
        "project": project,
        "total": total,
        "updatedAt": FieldValue.serverTimestamp(),
      },
      // Kalau pelajar ini tak pernah ada marks,
      // kita juga create createdAt sekali.
      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>> getStudentMarks(String studentId) {
    return students.doc(studentId).snapshots().map((snapshot) {
      if (!snapshot.exists) return {};
      final data = snapshot.data() as Map<String, dynamic>? ?? {};
      return data["marks"] ?? {};
    });
  }
}
