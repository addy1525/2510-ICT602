import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LecturerLoginPage extends StatefulWidget {
  const LecturerLoginPage({super.key});

  @override
  State<LecturerLoginPage> createState() => _LecturerLoginPageState();
}

class _LecturerLoginPageState extends State<LecturerLoginPage> {
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

      var snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!mounted) return;

      if (snap.exists && snap["role"] == "lecturer") {
        Navigator.pushReplacementNamed(context, '/lecturer');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Not a lecturer account.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login error: $e")),
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
                Text("Lecturer Login",
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium!
                        .copyWith(fontWeight: FontWeight.bold)),

                const SizedBox(height: 20),

                TextField(
                  controller: email,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.person_outline),
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

                FilledButton(
                  onPressed: loading ? null : login,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login"),
                ),

                const SizedBox(height: 25),
                const Divider(),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/admin-login');
                    },
                    child: const Text("Admin Login"),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/student-login');
                    },
                    child: const Text("Student Login"),
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