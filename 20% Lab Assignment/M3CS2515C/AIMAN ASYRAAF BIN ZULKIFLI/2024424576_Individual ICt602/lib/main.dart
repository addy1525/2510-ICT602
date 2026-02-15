import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/login_page.dart';
import 'pages/admin_home.dart';
import 'pages/lecturer_home.dart';
import 'pages/student_home.dart';
import 'pages/enter_marks.dart';
import 'pages/add_student.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
return MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
    useMaterial3: true,
  ),

  initialRoute: "/login",

  routes: {
    "/login": (context) => const LoginPage(),
    "/admin_home": (context) => const AdminHomePage(),
    "/lecturer_home": (context) => const LecturerHomePage(),
    "/student_home": (context) => const StudentHomePage(),
    "/enter_marks": (context) => const EnterMarksPage(),
    "/add_student": (context) => const AddStudentPage(),
  },
);

  }
}
