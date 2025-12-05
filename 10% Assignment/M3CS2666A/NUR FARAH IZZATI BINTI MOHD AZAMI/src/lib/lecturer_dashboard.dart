import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'login_page.dart';

class LecturerDashboard extends StatelessWidget {
  final TextEditingController studentId = TextEditingController();
  final TextEditingController test = TextEditingController();
  final TextEditingController assignment = TextEditingController();
  final TextEditingController project = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lecturer Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => LoginPage()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildTextField(studentId, "Student ID", false),
            buildTextField(test, "Test (20%)", true),
            buildTextField(assignment, "Assignment (10%)", true),
            buildTextField(project, "Project (20%)", true),
            const SizedBox(height: 20),

            // =====================================
            //  BUTTON SAVE CARRY MARK (UPDATED)
            // =====================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (studentId.text.isEmpty) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text("Enter Student ID")));
                    return;
                  }

                  double testScore = double.tryParse(test.text) ?? 0;
                  double assignmentScore = double.tryParse(assignment.text) ?? 0;
                  double projectScore = double.tryParse(project.text) ?? 0;

                  double total = testScore + assignmentScore + projectScore;

                  await FirestoreService().saveCarryMark(
                    studentId.text,
                    testScore,
                    assignmentScore,
                    projectScore,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Marks saved. Total: $total")),
                  );

                  studentId.clear();
                  test.clear();
                  assignment.clear();
                  project.clear();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.deepPurple,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // BUTTON TEXT UPDATED TO BLACK COLOR
                child: const Text(
                  "Save Carry Mark",
                  style: TextStyle(
                    color: Colors.white,       
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(
      TextEditingController controller, String label, bool isNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ),
    );
  }
}
