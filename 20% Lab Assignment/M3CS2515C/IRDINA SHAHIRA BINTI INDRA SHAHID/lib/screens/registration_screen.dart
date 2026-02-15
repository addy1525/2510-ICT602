// ========== REGISTRATION SCREEN ==========
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_screen.dart';
import 'lecturer_screen.dart';
import 'student_screen.dart';


class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _selectedRole = 'student';
  bool _isLoading = false;
  String _registrationStatus = '';

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
    _idController.text.isEmpty ||
    _emailController.text.isEmpty ||
    _passwordController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _registrationStatus = 'Creating account...';
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User user = userCredential.user!;

      setState(() {
        _registrationStatus = 'Account created! Saving profile...';
      });

      Map<String, dynamic> userData = {
        'uid': user.uid,
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim().toUpperCase(),
        'role': _selectedRole.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_selectedRole == 'student') {
        userData['matricNo'] = _idController.text.trim().toUpperCase();
      } else if (_selectedRole == 'lecturer') {
        userData['staffNo'] = _idController.text.trim().toUpperCase();
      } else if (_selectedRole == 'admin') {
        userData['adminId'] = _idController.text.trim().toUpperCase();
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData);

      print('✅ Registration successful for ${userData['name']}');

      setState(() {
        _isLoading = false;
        _registrationStatus = 'Registration successful!';
      });

      _navigateToRoleScreen(userData);

    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      String errorMsg = 'Registration failed: ';
      if (e.code == 'email-already-in-use') {
        errorMsg += 'Email already registered';
      } else if (e.code == 'weak-password') {
        errorMsg += 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        errorMsg += 'Invalid email format';
      } else {
        errorMsg += e.message ?? e.code;
      }

      _showError(errorMsg);
      _registrationStatus = 'Registration failed';

    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Unexpected error: $e');
      _registrationStatus = 'Error occurred';
    }
  }

  void _navigateToRoleScreen(Map<String, dynamic> userData) {
    Future.delayed(Duration(milliseconds: 1000), () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Account Registration'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
          child: Padding(
          padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Card(
            color: _isLoading ? Colors.blue[50] : Colors.purple[50],
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Icon(
                    _isLoading ? Icons.pending : Icons.app_registration,
                    color: _isLoading ? Colors.blue : Colors.purple,
                    size: 50,
                  ),
                  SizedBox(height: 10),
                  Text(
                    _isLoading ? _registrationStatus : 'CREATE NEW ACCOUNT',
                    style: TextStyle(
                      fontSize: 16,
                      color: _isLoading ? Colors.blue : Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 30),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELECT ROLE',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('STUDENT'),
                      ),
                      DropdownMenuItem(
                        value: 'lecturer',
                        child: Text('LECTURER'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('ADMINISTRATOR'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Text(
                    'PERSONAL INFORMATION',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      hintText: 'e.g., ALI BIN AHMAD',
                    ),
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      labelText: _selectedRole == 'student' ? 'Matric Number' :
                      _selectedRole == 'lecturer' ? 'Staff Number' : 'Admin ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                      hintText: _selectedRole == 'student' ? 'e.g., 2024255098' :
                      _selectedRole == 'lecturer' ? 'e.g., STAFF2024' : 'e.g., ADMIN001',
                    ),
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                      hintText: 'example@uitm.edu.my',
                    ),
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      hintText: 'At least 6 characters',
                    ),
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  SizedBox(height: 25),

                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton.icon(
                    onPressed: _register,
                    icon: Icon(Icons.person_add),
                    label: Text('CREATE ACCOUNT', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Already have an account? Login here'),
          ),
        ],
      ),
    ),
    ),
    );
  }
}