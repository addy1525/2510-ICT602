import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LecturerPage extends StatelessWidget {
  const LecturerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance.collection("users");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lecturer Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.where("role", isEqualTo: "student").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!.docs;

          if (students.isEmpty) {
            return const Center(child: Text("No students found"));
          }

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final studentId = student.id;
              final email = student["email"];

              return Card(
                child: ListTile(
                  title: Text(email),
                  subtitle: const Text("Tap to enter marks"),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditMarksPage(studentId: studentId, email: email),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EditMarksPage extends StatefulWidget {
  final String studentId;
  final String email;

  const EditMarksPage({Key? key, required this.studentId, required this.email}) : super(key: key);

  @override
  State<EditMarksPage> createState() => _EditMarksPageState();
}

class _EditMarksPageState extends State<EditMarksPage> {
  final testCtrl = TextEditingController();
  final assignCtrl = TextEditingController();
  final projectCtrl = TextEditingController();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    final doc = await FirebaseFirestore.instance.collection("marks").doc(widget.studentId).get();

    if (doc.exists) {
      final data = doc.data()!;
      testCtrl.text = (data["test"] ?? 0).toString();
      assignCtrl.text = (data["assignment"] ?? 0).toString();
      projectCtrl.text = (data["project"] ?? 0).toString();
    }

    setState(() => loading = false);
  }

  Future<void> _saveMarks() async {
    final test = double.tryParse(testCtrl.text) ?? 0;
    final assign = double.tryParse(assignCtrl.text) ?? 0;
    final project = double.tryParse(projectCtrl.text) ?? 0;

    await FirebaseFirestore.instance.collection("marks").doc(widget.studentId).set({
      "test": test,
      "assignment": assign,
      "project": project,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Marks saved successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Marks for ${widget.email}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: testCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Test (Max 20)"),
            ),

            TextField(
              controller: assignCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Assignment (Max 10)"),
            ),

            TextField(
              controller: projectCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Project (Max 20)"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saveMarks,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
