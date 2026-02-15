import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Starting ICT602 Grading System...');

  try {
    if (kIsWeb) {
      print('🌐 Platform: Web');

      // ⚠️⚠️⚠️ GANTI INI DENGAN CONFIG ANDA SENDIRI! ⚠️⚠️⚠️
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDnZ35aug-9LVSmZV4bO2ojPyrKhkAT_Xo", // GANTI
          authDomain: "ict602-flutter-app.firebaseapp.com", // GANTI
          projectId: "ict602-flutter-app", // GANTI
          storageBucket: "ict602-flutter-app.firebasestorage.app", // GANTI
          messagingSenderId: "486374809682", // GANTI
          appId: "1:486374809682:web:32d2d71b3c8c6b0507bf8b", // GANTI
        ),
      );
      print('✅ Firebase Web initialized successfully');
    } else {
      print('📱 Platform: Mobile');
      await Firebase.initializeApp();
      print('✅ Firebase Mobile initialized successfully');
    }
  } catch (e) {
    print('❌ CRITICAL ERROR: Firebase initialization failed');
    print('❌ Error details: $e');
    print('❌ Please check your Firebase configuration');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICT602 Grading System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}