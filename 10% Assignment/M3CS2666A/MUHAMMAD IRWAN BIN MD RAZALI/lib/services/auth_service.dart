import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  static Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance
          .signOut()
          .timeout(const Duration(seconds: 2));   // 🔥 Add timeout
    } catch (e) {
      // Ignore timeout error and proceed with logout
    }

    // Navigate immediately
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/student-login', (route) => false);
    }
  }
}
