import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ========== TEST PERMISSIONS SCREEN ==========
class TestPermissionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Permissions')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  // Test 1: Check auth
                  User? user = FirebaseAuth.instance.currentUser;
                  print('Auth user: ${user?.uid}');

                  // Test 2: Try to read users collection
                  QuerySnapshot snapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .limit(1)
                      .get();

                  print('✅ Read successful! Documents: ${snapshot.docs.length}');

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Connection successful!')),
                  );
                } on FirebaseException catch (e) {
                  print('❌ Firebase error: ${e.code} - ${e.message}');

                  String errorMsg = 'Error: ${e.code}\n';
                  if (e.code == 'permission-denied') {
                    errorMsg += 'Please update Firestore rules to allow read access.';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text('Test Firestore Read Permission'),
            ),
          ],
        ),
      ),
    );
  }
}