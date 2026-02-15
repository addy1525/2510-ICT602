import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/auth.dart';

class LoginPage extends StatefulWidget {
const LoginPage({Key? key}) : super(key: key);

@override
State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
String? errorMessage = '';
bool isLogin = true;

final TextEditingController _emailController = TextEditingController();
final TextEditingController _passwordController = TextEditingController();

String _selectedRole = "student";

Future<void> _login() async {
try {
await Auth().signInWithEmailAndPassword(
email: _emailController.text.trim(),
password: _passwordController.text.trim(),
);
} on FirebaseAuthException catch (e) {
setState(() => errorMessage = e.message);
}
}

Future<void> _register() async {
try {
await Auth().createUserWithEmailAndPassword(
email: _emailController.text.trim(),
password: _passwordController.text.trim(),
role: _selectedRole,
);
} on FirebaseAuthException catch (e) {
setState(() => errorMessage = e.message);
}
}

Widget _title() => const Text('ICT602 Project');

Widget _entryField(String title, TextEditingController controller) {
return TextField(
controller: controller,
obscureText: title.toLowerCase().contains("pass"),
decoration: InputDecoration(labelText: title),
);
}

Widget _roleDropdown() {
if (isLogin) return const SizedBox();

return DropdownButtonFormField<String>(
  value: _selectedRole,
  decoration: const InputDecoration(labelText: "Select Role"),
  items: const [
    DropdownMenuItem(value: "admin", child: Text("Admin")),
    DropdownMenuItem(value: "lecturer", child: Text("Lecturer")),
    DropdownMenuItem(value: "student", child: Text("Student")),
  ],
  onChanged: (value) => setState(() => _selectedRole = value!),
);

}

Widget _errorMessage() {
return Text(errorMessage == '' ? '' : '⚠ $errorMessage',
style: const TextStyle(color: Colors.red));
}

Widget _submitButton() {
return ElevatedButton(
onPressed: isLogin ? _login : _register,
child: Text(isLogin ? "Login" : "Register"),
);
}

Widget _loginOrRegisterButton() {
return TextButton(
onPressed: () => setState(() => isLogin = !isLogin),
child: Text(isLogin
? "Create an account"
: "Have an account? Sign in"),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: _title()),
body: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
children: [
_entryField('Email', _emailController),
_entryField('Password', _passwordController),
const SizedBox(height: 10),
_roleDropdown(),
const SizedBox(height: 10),
_errorMessage(),
const SizedBox(height: 10),
_submitButton(),
_loginOrRegisterButton(),
],
),
),
);
}
}
