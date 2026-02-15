import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin - Manage Users"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(),
        child: const Icon(Icons.person_add),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Search user email",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value.toLowerCase());
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("users").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs.where((user) {
                  return user["email"]
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text("No users found."));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final uid = user.id;
                    final email = user['email'];
                    final role = user['role'];

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(email),
                        subtitle: Text("Role: $role"),

                        trailing: PopupMenuButton(
                          onSelected: (value) {
                            if (value == "edit") _showEditUserDialog(uid, email, role);
                            if (value == "delete") _deleteUser(uid);
                            if (value == "reset") _resetPassword(email);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: "edit", child: Text("Edit User")),
                            const PopupMenuItem(value: "reset", child: Text("Reset Password")),
                            const PopupMenuItem(
                              value: "delete",
                              child: Text("Delete User", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = "student";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: "Password"), obscureText: true),

            DropdownButtonFormField<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: "admin", child: Text("Admin")),
                DropdownMenuItem(value: "lecturer", child: Text("Lecturer")),
                DropdownMenuItem(value: "student", child: Text("Student")),
              ],
              onChanged: (v) => role = v!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: emailCtrl.text.trim(),
                password: passCtrl.text.trim(),
              );

              await FirebaseFirestore.instance.collection("users").doc(cred.user!.uid).set({
                "email": emailCtrl.text.trim(),
                "role": role,
              });

              Navigator.pop(context);
            },
            child: const Text("Add User"),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(String uid, String email, String role) {
    String newRole = role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit User"),
        content: DropdownButtonFormField<String>(
          value: newRole,
          items: const [
            DropdownMenuItem(value: "admin", child: Text("Admin")),
            DropdownMenuItem(value: "lecturer", child: Text("Lecturer")),
            DropdownMenuItem(value: "student", child: Text("Student")),
          ],
          onChanged: (v) => newRole = v!,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection("users").doc(uid).update({
                "role": newRole,
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String uid) async {
    await FirebaseFirestore.instance.collection("users").doc(uid).delete();
  }

  Future<void> _resetPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Password reset email sent to $email")),
    );
  }
}
