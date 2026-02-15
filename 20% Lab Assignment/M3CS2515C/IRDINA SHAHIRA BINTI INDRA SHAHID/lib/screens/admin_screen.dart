import 'welcome_screen.dart';
import 'package:flutter/material.dart';

// ========== ADMIN SCREEN ==========
class AdminScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  AdminScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => WelcomeScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text('Welcome, ${user['name']}!', style: TextStyle(fontSize: 24)),
            SizedBox(height: 10),
            Text('Role: ${user['role']?.toUpperCase()}', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 10),
            if (user.containsKey('adminId'))
              Text('Admin ID: ${user['adminId']}'),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('System Management')),
            );
            },
              child: Text('System Management'),
            ),
          ],
        ),
      ),
    );
  }
}
