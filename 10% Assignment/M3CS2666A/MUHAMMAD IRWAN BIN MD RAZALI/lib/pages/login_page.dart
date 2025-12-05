import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;

  login() async {
    try {
      setState(() => loading = true);

      UserCredential user = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: email.text.trim(), password: password.text.trim());

      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.user!.uid)
          .get();

      String role = userData["role"];

      if (role == "admin") {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (role == "lecturer") {
        Navigator.pushReplacementNamed(context, '/lecturer');
      } else {
        Navigator.pushReplacementNamed(context, '/student');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Login failed: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("ICT602 Login",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: email, decoration: InputDecoration(labelText: "Email")),
              const SizedBox(height: 10),
              TextField(controller: password, decoration: InputDecoration(labelText: "Password"), obscureText: true),
              const SizedBox(height: 20),
              loading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: login,
                      child: Text("Login"),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
