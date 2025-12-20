// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {

    if (kIsWeb) {
      return const FirebaseOptions(
        // PASTE YOUR CONFIG VALUES HERE
        apiKey: "AIzaSyB0d2UxSGJk7aOOM2sRL48mHAhXFMh6VM4", 
        appId: "1:233031395414:android:3297b5ae2c161fddf3f3f7",
        messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
        projectId: "lab-flutter-86eb2",
        authDomain: "lab-flutter-86eb2.firebaseapp.com", 
        storageBucket: "lab-flutter-86eb2.appspot.com",
      );
    } 

    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }
}