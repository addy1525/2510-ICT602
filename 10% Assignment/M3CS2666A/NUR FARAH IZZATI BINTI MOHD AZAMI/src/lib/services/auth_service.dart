import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  Future<String> login(String email, String password, String role) async {
    try {
      // Collection ikut role
      final usersCollection =
          FirebaseFirestore.instance.collection(role + 's');

      final snapshot = await usersCollection
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return role; // return admin / lecturer / student
      } else {
        return "invalid";
      }
    } catch (e) {
      print("Login error: $e");
      return "invalid";
    }
  }
}
