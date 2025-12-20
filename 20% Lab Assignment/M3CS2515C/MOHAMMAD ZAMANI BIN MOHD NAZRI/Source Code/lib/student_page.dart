import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class StudentPage extends StatefulWidget {
  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  String? userUid;
  Map<String, dynamic>? studentMarks;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setState(() {
          userUid = currentUser.uid;
        });
        
        if (userUid != null) {
          _loadMarks();
        }
      }
    } catch (e) {
      print('Error loading student data: $e');
    }
  }

  Future<void> _loadMarks() async {
    if (userUid == null) return;

    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('marks')
          .doc(userUid)
          .get();

      if (docSnapshot.exists) {
        var data = docSnapshot.data() as Map<String, dynamic>;
        
        setState(() {
          studentMarks = data;
        });
      } else {
        print('No document found for UID: $userUid');
      }
    } catch (e) {
      print('Error loading marks: $e');
    }
  }

  Map<String, double> calculateTargets(double carryMark) {
    return {
      'A+': 90 - carryMark,
      'A': 80 - carryMark,
      'A-': 75 - carryMark,
      'B+': 70 - carryMark,
      'B': 65 - carryMark,
      'B-': 60 - carryMark,
      'C+': 55 - carryMark,
      'C': 50 - carryMark,
    };
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    double test = studentMarks != null ? (studentMarks!['test'] ?? 0).toDouble() : 0;
    double assignment = studentMarks != null ? (studentMarks!['assignment'] ?? 0).toDouble() : 0;
    double project = studentMarks != null ? (studentMarks!['project'] ?? 0).toDouble() : 0;
    double carryMark = test + assignment + project;
    Map<String, double> targets = calculateTargets(carryMark);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/bg3.jpeg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 75, left: 20, right: 20),
                  child: SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                Text(
                                  "Student Dashboard",
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 9
                                      ..color = const Color.fromARGB(255, 210, 206, 206),
                                  ),
                                ),
                                Text(
                                  "Student Dashboard",
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(0, 0, 0, 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          if (studentMarks == null)
                            Center(
                              child: Text(
                                'No marks available',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else ...[
                            Text(
                              'Your Marks',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Test: ${test.toStringAsFixed(1)}/20',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Assignment: ${assignment.toStringAsFixed(1)}/10',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Project: ${project.toStringAsFixed(1)}/20',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            Divider(thickness: 2, height: 20),
                            Text(
                              'Total Carry Mark: ${carryMark.toStringAsFixed(1)}/50',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Final Exam Targets (out of 50)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            SizedBox(height: 10),
                            Table(
                              border: TableBorder.all(
                                color: Colors.black,
                                width: 2,
                              ),
                              columnWidths: {
                                0: FlexColumnWidth(1),
                                1: FlexColumnWidth(2),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                  ),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Text(
                                        'Grade',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Text(
                                        'Required Marks',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                ...targets.entries.where((entry) {
                                  return entry.value >= 0 && entry.value <= 50;
                                }).map((entry) {
                                  String grade = entry.key;
                                  double requiredMark = entry.value;
                                  
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Text(
                                          grade,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Text(
                                          '${requiredMark.toStringAsFixed(1)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                            SizedBox(height: 10),
                            if (targets.values.every((mark) => mark < 0))
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  'Congratulations! You have secured the highest grade possible!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (targets.values.every((mark) => mark > 50))
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  'Not achievable with current carry marks.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 65),
                child: GestureDetector(
                  onTap: _logout,
                  child: Container(
                    width: 150,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                        width: 3,
                      ),
                      color: const Color.fromARGB(255, 239, 0, 0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}