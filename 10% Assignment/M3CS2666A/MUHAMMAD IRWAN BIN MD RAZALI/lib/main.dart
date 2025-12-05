import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ict602_assignment/pages/student_register.dart';
import 'firebase_options.dart';
import 'pages/student_login.dart';
import 'pages/lecturer_login.dart';
import 'pages/admin_login.dart';
import 'pages/student_page.dart';
import 'pages/lecturer_page.dart';
import 'pages/admin_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.deepPurple, 
  ),
  initialRoute: '/student-login',
  routes: {
    '/student-login': (context) => const StudentLoginPage(),
    '/lecturer-login': (context) => const LecturerLoginPage(),
    '/admin-login': (context) => const AdminLoginPage(),
    '/student-register': (context) => const StudentRegisterPage(),
    '/student': (context) => const StudentPage(),
    '/lecturer': (context) => const LecturerPage(),
    '/admin': (context) => const AdminPage(),
  },
);
  }
}
