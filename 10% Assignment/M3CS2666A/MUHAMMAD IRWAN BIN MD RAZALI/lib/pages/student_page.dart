import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class StudentPage extends StatelessWidget {
  const StudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Carry Marks"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.logout(context),
          ),
        ],
      ),
      body: StreamBuilder(
          stream:
              FirebaseFirestore.instance.collection("marks").snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var docs = snapshot.data!.docs;
            var data = docs.where((d) => d["studentId"] == uid).isNotEmpty
                ? docs.firstWhere((d) => d["studentId"] == uid)
                : null;

            if (data == null) {
              return const Center(
                child: Text(
                  "Your lecturer has not entered your marks yet.",
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            double carry = data["totalCarry"];
            double needAplus = (90 - carry);
            double needA = (80 - carry);
            double needAminus = (75 - carry);
            double needBplus = (70 - carry);
            double needB = (65 - carry);
            double needBminus = (60 - carry);
            double needCplus = (55 - carry);
            double needC = (50 - carry);

            List<Map<String, dynamic>> gradeData = [
              {"grade": "A+", "range": "90–100", "needed": needAplus},
              {"grade": "A", "range": "80–89", "needed": needA},
              {"grade": "A−", "range": "75–79", "needed": needAminus},
              {"grade": "B+", "range": "70–74", "needed": needBplus},
              {"grade": "B", "range": "65–69", "needed": needB},
              {"grade": "B−", "range": "60–64", "needed": needBminus},
              {"grade": "C+", "range": "55–59", "needed": needCplus},
              {"grade": "C", "range": "50–54", "needed": needC},
            ];

            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Carry Marks",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("$carry / 50",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall!
                                  .copyWith(color: Colors.deepPurple)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Final Exam Score Needed:",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  const SizedBox(height: 10),

                  ...gradeData.map((item) => Card(
                        elevation: 1,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Text(
                              item["grade"],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ),
                          title: Text(
                              "Grade ${item["grade"]} (${item["range"]})"),
                          subtitle: Text(
                              "Required Final Exam Marks: ${item["needed"].toStringAsFixed(1)}"),
                        ),
                      )),
                ],
              ),
            );
          }),
    );
  }
}