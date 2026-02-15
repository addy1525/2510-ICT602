import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'registration_screen.dart';
import 'admin_screen.dart';
import 'lecturer_screen.dart';
import 'student_screen.dart';
import 'test_permissions_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static Map<String, Map<String, dynamic>> _userCache = {};

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _loginStatus = 'Ready to login';

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _loginStatus = 'Authenticating...';
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User user = userCredential.user!;

      setState(() {
        _loginStatus = 'Login successful! Loading profile...';
      });

      await _handleFirebaseLoginSuccess(user);

    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      String errorMsg = 'Login failed: ';
      switch (e.code) {
        case 'user-not-found':
          errorMsg += 'No user found with this email';
          break;
        case 'wrong-password':
          errorMsg += 'Wrong password';
          break;
        case 'invalid-email':
          errorMsg += 'Invalid email format';
          break;
        default:
          errorMsg += e.message ?? e.code;
      }

      _showError(errorMsg);
      _loginStatus = 'Login failed';

    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Unexpected error: $e');
      _loginStatus = 'Error occurred';
    }
  }

  Future<void> _handleFirebaseLoginSuccess(User user) async {
    try {
      String cacheKey = user.uid;

      if (_userCache.containsKey(cacheKey)) {
        print('✅ Using cached user data');
        Map<String, dynamic> userData = _userCache[cacheKey]!;

        userData['authUid'] = user.uid;
        userData['authEmail'] = user.email;

        _navigateToRoleScreen(userData);
        return;
      }

      setState(() {
        _loginStatus = 'Loading user profile...';
      });

      DocumentSnapshot userDoc;
      try {
        userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(Duration(seconds: 10));
      } on TimeoutException {
        _showError('Connection timeout. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        if (!userData.containsKey('role')) {
          print('⚠️ User missing role field! Adding default...');

          String role = 'student';
          if (user.email?.contains('lecturer') == true ||
              user.email?.contains('staff') == true) {
            role = 'lecturer';
          } else if (user.email?.contains('admin') == true) {
            role = 'admin';
          }

          await userDoc.reference.update({
            'role': role.toLowerCase(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          userData['role'] = role.toLowerCase();
          print('✅ Added role: ${role.toLowerCase()} to user');
        }

        _userCache[cacheKey] = Map<String, dynamic>.from(userData);

        userData['authUid'] = user.uid;
        userData['authEmail'] = user.email;

        print('✅ User profile loaded - Role: ${userData['role']}');

        _navigateToRoleScreen(userData);

      } else {
        _showError('User profile not found in database');
        await _auth.signOut();
        setState(() => _isLoading = false);
      }

    } catch (e) {
      print('Login error: $e');
      _showError('Error loading profile: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  void _navigateToRoleScreen(Map<String, dynamic> userData) {
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() => _isLoading = false);

      switch (userData['role']) {
        case 'admin':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminScreen(user: userData),
            ),
          );
          break;
        case 'lecturer':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LecturerScreen(user: userData),
            ),
          );
          break;
        case 'student':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StudentScreen(user: userData),
            ),
          );
          break;
        default:
          _showError('Unknown user role: ${userData['role']}');
          setState(() => _isLoading = false);
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  static void clearCache() {
    _userCache.clear();
    print('🗑️ User cache cleared');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login to System'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                color: _isLoading ? Colors.blue[50] : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      Icon(
                        _isLoading ? Icons.pending : Icons.verified,
                        color: _isLoading ? Colors.blue : Colors.green,
                        size: 50,
                      ),
                      SizedBox(height: 10),
                      Text(
                        _loginStatus,
                        style: TextStyle(
                          fontSize: 16,
                          color: _isLoading ? Colors.blue : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 5),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'LOGIN TO SYSTEM',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),

                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                          hintText: 'your.email@uitm.edu.my',
                        ),
                      ),
                      SizedBox(height: 15),

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      SizedBox(height: 15),

                      OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TestPermissionsScreen()),
                        ),
                        child: Text('Test Firebase Connection'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.orange),
                        ),
                      ),

                      SizedBox(height: 25),

                      _isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton.icon(
                        onPressed: _login,
                        icon: Icon(Icons.login),
                        label: Text('LOGIN', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegistrationScreen()),
                  );
                },
                child: Text('Don\'t have an account? Register here'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}