import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({Key? key}) : super(key: key);

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  Map<String, dynamic>? marks;
  String selectedGrade = "A+";
  String resultText = "";

  final Map<String, double> gradeTargets = {
    "A+": 90,
    "A": 80,
    "A-": 75,
    "B+": 70,
    "B": 65,
    "B-": 60,
    "C+": 55,
    "C": 50,
  };

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("marks")
        .doc(uid)
        .get();

    if (doc.exists) {
      setState(() => marks = doc.data());
    } else {
      setState(() => marks = {
            "test": 0,
            "assignment": 0,
            "project": 0,
          });
    }
  }

  double get carryMark {
    final test = (marks?["test"] ?? 0).toDouble();
    final assignment = (marks?["assignment"] ?? 0).toDouble();
    final project = (marks?["project"] ?? 0).toDouble();
    return test + assignment + project;
  }

  void calculateFinalNeeded() {
    final target = gradeTargets[selectedGrade]!;
    final needed = target - carryMark;

    double finalExamRequired = (needed / 50) * 100;

    if (finalExamRequired < 0) finalExamRequired = 0;
    if (finalExamRequired > 100) {
      resultText = "⚠ Impossible to reach $selectedGrade";
    } else {
      resultText =
          "To get $selectedGrade, you need ${finalExamRequired.toStringAsFixed(2)}% in Final Exam";
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (marks == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Carry Marks",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Text("Test: ${marks!["test"]} / 20"),
            Text("Assignment: ${marks!["assignment"]} / 10"),
            Text("Project: ${marks!["project"]} / 20"),

            const Divider(height: 30),

            Text(
              "Total Carry Mark: ${carryMark.toStringAsFixed(2)} / 50",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const Divider(height: 30),

            const Text(
              "Target Grade Calculator",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            DropdownButton<String>(
              value: selectedGrade,
              items: gradeTargets.keys
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => selectedGrade = v!),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: calculateFinalNeeded,
              child: const Text("Calculate Final Exam Marks"),
            ),

            const SizedBox(height: 15),

            Text(
              resultText,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
