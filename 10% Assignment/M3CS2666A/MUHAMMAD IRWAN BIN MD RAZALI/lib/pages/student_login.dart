import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({super.key});

  @override
  State<StudentLoginPage> createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);
    try {
      UserCredential user = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      var uid = user.user!.uid;

      var snap =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      if (!mounted) return;

      if (snap.exists && snap["role"] == "student") {
        Navigator.pushReplacementNamed(context, '/student');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Not a student account.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Student Login",
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium!
                        .copyWith(fontWeight: FontWeight.bold)),

                const SizedBox(height: 20),

                TextField(
                  controller: email,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 25),

                Center(
                  child: FilledButton(
                    onPressed: loading ? null : login,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Login"),
                  ),
                ),

                const SizedBox(height: 25),
                const Divider(),

                Center(
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/lecturer-login');
                        },
                        child: const Text("Lecturer Login"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/admin-login');
                        },
                        child: const Text("Admin Login"),
                      ),
                      TextButton(
                      onPressed: () {
                      Navigator.pushNamed(context, '/student-register');
                      },
                      child: const Text("Create Student Account"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
