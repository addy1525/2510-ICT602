import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICT602 Assignment 1',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: LoginScreen(),
    );
  }
}
