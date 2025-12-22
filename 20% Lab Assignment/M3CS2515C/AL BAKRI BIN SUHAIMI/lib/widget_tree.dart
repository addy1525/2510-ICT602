import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:myapp/login_register_page.dart';
import 'package:myapp/admin_page.dart';
import 'package:myapp/lecturer_page.dart';
import 'package:myapp/student_page.dart';

class WidgetTree extends StatefulWidget {
const WidgetTree({Key? key}) : super(key: key);

@override
State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
@override
Widget build(BuildContext context) {
return StreamBuilder<User?>(
stream: FirebaseAuth.instance.authStateChanges(),
builder: (context, snapshot) {

if (!snapshot.hasData) return const LoginPage();


    final user = snapshot.data!;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No user data found."),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      },
                      child: const Text("Sign Out"),
                      ),
                      ],
                      ),
                      ),
                      );
                      }
                      final data = snap.data!;
                      final role = data['role'] ?? 'student';
        if (role == 'admin') return const AdminPage();
        if (role == 'lecturer') return const LecturerPage();
        return const StudentPage();
      },
    );
  },
);

}
}
