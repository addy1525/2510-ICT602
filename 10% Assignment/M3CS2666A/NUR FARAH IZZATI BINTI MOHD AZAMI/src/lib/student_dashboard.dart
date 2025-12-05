import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'login_page.dart';

class StudentDashboard extends StatelessWidget {
  final TextEditingController studentId = TextEditingController();

  final Color primary = const Color(0xFF6A5AE0); // Soft UiTM Purple
  final Color accent = const Color(0xFFFFD56B); // Pastel Gold
  final Color bg = const Color(0xFFF5F5F7); // Light grey background

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text(
          "Student Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
            },
          ),
        ],
      ),

      // ==========================================================
      // BODY CONTENT
      // ==========================================================
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // Title
            Text(
              "Check Your Carry Marks",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),

            const SizedBox(height: 25),

            // STUDENT ID INPUT CARD
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: studentId,
                  decoration: InputDecoration(
                    labelText: "Enter Student ID",
                    prefixIcon: Icon(Icons.person, color: primary),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (studentId.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter Student ID")),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MarkView(studentId: studentId.text),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  "View Marks",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
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
}

// ===============================================================
//               MARK VIEW PAGE
// ===============================================================

class MarkView extends StatelessWidget {
  final String studentId;

  MarkView({required this.studentId});

  final Color primary = const Color(0xFF6A5AE0);
  final Color accent = const Color(0xFFFFD56B);
  final Color bg = const Color(0xFFF5F5F7);

  Map<String, double> calculateTarget(double carry) {
    return {
      "A+": 90 - carry,
      "A": 80 - carry,
      "A-": 75 - carry,
      "B+": 70 - carry,
      "B": 65 - carry,
      "B-": 60 - carry,
      "C+": 55 - carry,
      "C": 50 - carry,
    };
  }

  String statusText(double value) {
    if (value <= 0) return "Achieved ✔";
    if (value > 50) return "Not possible ❌";
    return "Need: ${value.toStringAsFixed(1)} / 50";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text("Your Marks", style: TextStyle(color: Colors.white)),
      ),

      body: StreamBuilder<Map<String, dynamic>>(
        stream: FirestoreService().getStudentMarks(studentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final test = data["test"]?.toDouble() ?? 0;
          final assignment = data["assignment"]?.toDouble() ?? 0;
          final project = data["project"]?.toDouble() ?? 0;
          final total = test + assignment + project;

          final target = calculateTarget(total);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // =====================================================
                //  CARRY MARK CARD
                // =====================================================
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Carry Mark Breakdown",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _scoreRow("Test", test),
                        _scoreRow("Assignment", assignment),
                        _scoreRow("Project", project),

                        const Divider(),
                        Text(
                          "Total: $total / 50",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // =====================================================
                //  TARGET SCORE CARD
                // =====================================================
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          "Final Exam Requirement",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        ...target.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 15),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${entry.key} Grade",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  statusText(entry.value),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =======================================================
  //   REUSABLE ROW FOR SCORES
  // =======================================================
  Widget _scoreRow(String title, double mark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text("$mark / 20",
              style: const TextStyle(fontSize: 16, color: Colors.black87)),
        ],
      ),
    );
  }
}
