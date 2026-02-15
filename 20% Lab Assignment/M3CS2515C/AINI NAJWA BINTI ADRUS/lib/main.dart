import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/lecturer_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICT602 Course Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Add this for newer Flutter versions
      ),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.currentUser == null) {
            return const LoginScreen();
          } else {
            if (authProvider.isAdmin()) {
              return const AdminDashboard();
            } else if (authProvider.isLecturer()) {
              return const LecturerDashboard();
            } else {
              return const StudentDashboard();
            }
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
