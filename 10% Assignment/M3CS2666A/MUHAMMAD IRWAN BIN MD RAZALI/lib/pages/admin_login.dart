import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);

    try {
      UserCredential user = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: email.text.trim(), password: password.text.trim());

      var uid = user.user!.uid;

      var snap =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      if (!mounted) return;

      if (snap.exists && snap["role"] == "admin") {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Not an admin account.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: $e")));
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
              children: [
                Text("Admin Login",
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium!
                        .copyWith(fontWeight: FontWeight.bold)),

                const SizedBox(height: 20),

                TextField(
                  controller: email,
                  decoration: const InputDecoration(
                    labelText: "Admin Email",
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
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

                const SizedBox(height: 20),
                const Divider(),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/lecturer-login');
                  },
                  child: const Text("Lecturer Login"),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/student-login');
                  },
                  child: const Text("Student Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
