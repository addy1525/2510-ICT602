import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class LecturerPage extends StatefulWidget {
  @override
  State<LecturerPage> createState() => _LecturerPageState();
}

class _LecturerPageState extends State<LecturerPage> {
  String? selectedStudentUid;
  Map<String, String> students = {}; 
  TextEditingController _testController = TextEditingController();
  TextEditingController _assignmentController = TextEditingController();
  TextEditingController _projectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      Map<String, String> studentMap = {};
      for (var doc in userSnapshot.docs) {
        String uid = doc.id;
        var userData = doc.data() as Map<String, dynamic>;
        
        String displayName = uid; 
        
        if (userData.containsKey('email')) {
          String email = userData['email'];
          displayName = email.split('@')[0];
        }
        
        studentMap[uid] = displayName;
      }

      setState(() {
        students = studentMap;
      });

    } catch (e) {
      print('Error loading students: $e');
    }
  }

  void _submitMarks() async {
    String test = _testController.text.trim();
    String assignment = _assignmentController.text.trim();
    String project = _projectController.text.trim();

    if (selectedStudentUid == null || test.isEmpty || assignment.isEmpty || project.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    try {
      double testMark = double.parse(test);
      double assignmentMark = double.parse(assignment);
      double projectMark = double.parse(project);

      // Validate marks
      if (testMark < 0 || testMark > 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test mark must be between 0 and 20')),
        );
        return;
      }
      if (assignmentMark < 0 || assignmentMark > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assignment mark must be between 0 and 10')),
        );
        return;
      }
      if (projectMark < 0 || projectMark > 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project mark must be between 0 and 20')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('marks').doc(selectedStudentUid).set({
        'test': testMark,
        'assignment': assignmentMark,
        'project': projectMark,
        'submittedAt': FieldValue.serverTimestamp(),
        'submittedBy': FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marks submitted successfully for ${students[selectedStudentUid]}!')),
      );

      // Clear the form
      setState(() {
        selectedStudentUid = null;
      });
      _testController.clear();
      _assignmentController.clear();
      _projectController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting marks: $e')),
      );
    }
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
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          width: 5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(30),
                      child: Column(
                        children: <Widget>[
                          Stack(
                            children: [
                              Text(
                                "Lecturer Page",
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 11
                                    ..color = const Color.fromARGB(255, 210, 206, 206),
                                ),
                              ),
                              Text(
                                "Lecturer Page",
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(0, 0, 0, 1),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 235, 227, 227),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedStudentUid,
                                hint: Text('Select Student'),
                                isExpanded: true,
                                items: students.entries.map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedStudentUid = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 235, 227, 227),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _testController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Test Mark (out of 20)",
                                contentPadding: EdgeInsets.all(20),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 235, 227, 227),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _assignmentController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Assignment Mark (out of 10)",
                                contentPadding: EdgeInsets.all(20),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 235, 227, 227),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _projectController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Project Mark (out of 20)",
                                contentPadding: EdgeInsets.all(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            print('Submit tapped');
                            _submitMarks();
                          },
                          child: Container(
                            width: 150,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black,
                                width: 3,
                              ),
                              color: const Color.fromARGB(255, 3, 246, 19),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        GestureDetector(
                          onTap: _logout,
                          child: Container(
                            width: 150,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black,
                                width: 3,
                              ),
                              color: const Color.fromARGB(255, 255, 0, 0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}