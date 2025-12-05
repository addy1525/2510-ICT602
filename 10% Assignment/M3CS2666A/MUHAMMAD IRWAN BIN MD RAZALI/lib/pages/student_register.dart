import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentRegisterPage extends StatefulWidget {
  const StudentRegisterPage({super.key});

  @override
  State<StudentRegisterPage> createState() => _StudentRegisterPageState();
}

class _StudentRegisterPageState extends State<StudentRegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> register() async {
    setState(() => loading = true);

    try {
      // Create user
      UserCredential user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      String uid = user.user!.uid;

      // Save in Firestore
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "uid": uid,
        "name": name.text.trim(),
        "email": email.text.trim(),
        "role": "student",
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful")),
      );

      Navigator.pushReplacementNamed(context, '/student-login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Registration"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: email,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 25),

            FilledButton(
              onPressed: loading ? null : register,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Register"),
            ),

            const SizedBox(height: 20),
            TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/student-login'),
                child: const Text("Already have an account? Login"))
          ],
        ),
      ),
    );
  }
}
