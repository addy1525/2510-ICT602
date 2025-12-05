import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class LecturerPage extends StatefulWidget {
  const LecturerPage({super.key});

  @override
  State<LecturerPage> createState() => _LecturerPageState();
}

class _LecturerPageState extends State<LecturerPage> {
  String? selectedStudent;
  final test = TextEditingController();
  final assignment = TextEditingController();
  final project = TextEditingController();

  Future<void> saveMarks() async {
    if (selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a student.")),
      );
      return;
    }

    try {
      double t = double.parse(test.text);
      double a = double.parse(assignment.text);
      double p = double.parse(project.text);

      await FirebaseFirestore.instance
          .collection("marks")
          .doc(selectedStudent)
          .set({
        "studentId": selectedStudent,
        "test": t,
        "assignment": a,
        "project": p,
        "totalCarry": t + a + p,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Marks Saved")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lecturer Panel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text("Select Student",
                style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: 10),

            StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .where("role", isEqualTo: "student")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  var students = snapshot.data!.docs;

                  return DropdownMenu(
                    width: double.infinity,
                    requestFocusOnTap: false,
                    hintText: "Choose student",
                    onSelected: (value) {
                      setState(() => selectedStudent = value);
                    },
                    dropdownMenuEntries: students
                      .map((doc) => DropdownMenuEntry(
                      value: doc.id,          // USE DOCUMENT ID
                      label: doc["name"],     // Student Name
                      ))
                      .toList(),
                  );
                }),

            const SizedBox(height: 25),

            TextField(
              controller: test,
              decoration: const InputDecoration(
                labelText: "Test (20%)",
                prefixIcon: Icon(Icons.scoreboard_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 15),

            TextField(
              controller: assignment,
              decoration: const InputDecoration(
                labelText: "Assignment (10%)",
                prefixIcon: Icon(Icons.task_alt_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 15),

            TextField(
              controller: project,
              decoration: const InputDecoration(
                labelText: "Project (20%)",
                prefixIcon: Icon(Icons.build_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 25),

            FilledButton.icon(
              onPressed: saveMarks,
              icon: const Icon(Icons.save),
              label: const Text("Save Marks"),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}