import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ict602_app/services/notification_service.dart';
import 'analytics_screen.dart';
import 'attendance_screen.dart';
import 'lecturer_notification_screen.dart';
import 'lecturer_peer_assessment_screen.dart';
import 'test_permissions_screen.dart';
import 'welcome_screen.dart';

// ========== LECTURER SCREEN ==========
class LecturerScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  LecturerScreen({required this.user});

  @override
  _LecturerScreenState createState() => _LecturerScreenState();
}

class _LecturerScreenState extends State<LecturerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _selectedStudent;
  bool _loadingStudents = true;

  final TextEditingController _testMarkController = TextEditingController();
  final TextEditingController _assignmentMarkController = TextEditingController();
  final TextEditingController _projectMarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudentsFromFirestore();
  }

  Future<void> _loadStudentsFromFirestore() async {
    try {
      print('🔍 Loading students from Firestore...');

      setState(() { _loadingStudents = true; });

      // Cek authentication dulu
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No user authenticated');
        setState(() { _loadingStudents = false; });
        _showError('Please login again');
        return;
      }

      print('✅ User authenticated: ${currentUser.uid}');

      QuerySnapshot allUsers = await _firestore.collection('users').get();

      print('📊 Total documents in "users" collection: ${allUsers.docs.length}');

      List<Map<String, dynamic>> studentsList = [];

      for (var doc in allUsers.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        // DEBUG: Print semua data
        print('User data: $userData');

        bool isStudent = false;

        if (userData.containsKey('role')) {
          // PERBAIKAN: Case-insensitive comparison
          String roleValue = userData['role'].toString();
          print('Raw role: "$roleValue"');

          // Normalize to lowercase for comparison
          String normalizedRole = roleValue.toLowerCase();
          print('Normalized role: "$normalizedRole"');

          // Accept multiple possible spellings
          if (normalizedRole == 'student' ||  normalizedRole.contains('student')) {
    isStudent = true;
    print('✅ Identified as student');
    }
    } else {
    print('⚠️ Role field missing!');
    }

    if (isStudent) {
    studentsList.add({
    'uid': doc.id,
    ...userData,
    });
    }
    }

    print('🎯 Found ${studentsList.length} students');

    // Sort students by name
    studentsList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

    setState(() {
    _students = studentsList;
    _loadingStudents = false;
    });

    if (studentsList.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
    content: Text('No students found.'),
    backgroundColor: Colors.orange,
    duration: Duration(seconds: 5),
    ),
    );
    }

    } on FirebaseException catch (e) {
    print('❌ FIREBASE ERROR: ${e.code} - ${e.message}');

    if (e.code == 'permission-denied') {
    _showError('Permission denied. Please check Firestore rules.');
    } else {
    _showError('Firestore error: ${e.message}');
    }

    setState(() { _loadingStudents = false; });
    } catch (e) {
    print('❌ GENERAL ERROR: $e');
    _showError('Error: $e');
    setState(() { _loadingStudents = false; });
    }
  }

  Future<void> _saveMarksToFirestore() async {
    if (_selectedStudent == null) {
      _showError('Please select a student');
      return;
    }

// Send notification
    await NotificationService.sendNotificationToUser(
    userId: _selectedStudent!['uid'],
    title: '📊 Marks Updated',
    body: 'Your ICT602 carry marks have been updated by ${widget.user['name']}',
    type: 'marks_update',
    data: {
    'type': 'marks_updated',
    'studentUid': _selectedStudent!['uid'],
    'lecturerName': widget.user['name'],
    },
    );

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
    _showError('User not authenticated');
    return;
    }

    double testMark = double.tryParse(_testMarkController.text) ?? 0;
    double assignmentMark = double.tryParse(_assignmentMarkController.text) ?? 0;
    double projectMark = double.tryParse(_projectMarkController.text) ?? 0;

    if (testMark > 20 || assignmentMark > 10 || projectMark > 20) {
    _showError('Marks exceed maximum limits');
    return;
    }

    try {
    Map<String, dynamic> marksData = {
    'matricNo': _selectedStudent!['matricNo'],
    'studentName': _selectedStudent!['name'],
    'studentUid': _selectedStudent!['uid'],
    'test': testMark,
    'assignment': assignmentMark,
    'project': projectMark,
    'totalCarry': testMark + assignmentMark + projectMark,
    'lecturerId': currentUser.uid,
    'lecturerEmail': currentUser.email,
    'lecturerName': widget.user['name'],
    'lecturerStaffNo': widget.user['staffNo'],
    'updatedAt': FieldValue.serverTimestamp(),
    'courseCode': 'ICT602',
    'courseName': 'Fundamentals of Software Development',
    };

    await _firestore
        .collection('carry_marks')
        .doc(_selectedStudent!['matricNo'])
        .set(marksData, SetOptions(merge: true));

    print('✅ Marks saved successfully!');

    _showSuccessDialog(testMark, assignmentMark, projectMark);

    } on FirebaseException catch (e) {
    print('🔥 FIREBASE ERROR: ${e.code} - ${e.message}');
    _showError('Firestore error: ${e.message}');
    } catch (e) {
    print('❌ General error: $e');
    _showError('Failed to save: $e');
    }
  }

  void _showSuccessDialog(double testMark, double assignmentMark, double projectMark) {
    double totalCarryMark = testMark + assignmentMark + projectMark;
    double totalCarryPercent = (totalCarryMark / 50) * 100;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('✅ Marks Saved Successfully!'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Student: ${_selectedStudent!['name']}', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Matric: ${_selectedStudent!['matricNo']}'),
              SizedBox(height: 15),
              Text('📊 Marks Breakdown:'),
              SizedBox(height: 5),
              Text('• Test: $testMark/20'),
              Text('• Assignment: $assignmentMark/10'),
              Text('• Project: $projectMark/20'),
              SizedBox(height: 10),
              Divider(),
              Text('TOTAL CARRY MARK:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$totalCarryMark/50 (${totalCarryPercent.toStringAsFixed(1)}%)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              SizedBox(height: 10),
              Text('✅ Student can now view these marks in their app'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearForm();
              Navigator.pop(context);
            },
            child: Text('CONTINUE'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    setState(() { _selectedStudent = null; });
    _testMarkController.clear();
    _assignmentMarkController.clear();
    _projectMarkController.clear();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lecturer Panel'),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AnalyticsScreen(user: widget.user)),
            ),
            tooltip: 'Analytics',
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LecturerNotificationScreen(user: widget.user)),
            ),
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: Icon(Icons.group),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AttendanceScreen(user: widget.user)),
            ),
            tooltip: 'Attendance',
          ),
          IconButton(
            icon: Icon(Icons.group_work),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LecturerPeerAssessmentScreen(user: widget.user)),
            ),
            tooltip: 'Peer Assessments',
          ),
          IconButton(
            icon: Icon(Icons.bug_report, color: Colors.orange),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TestPermissionsScreen()),
            ),
            tooltip: 'Test Permissions',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStudentsFromFirestore,
            tooltip: 'Refresh student list',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => WelcomeScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      Icon(Icons.school, size: 60, color: Colors.green),
                      SizedBox(height: 10),
                      Text('Welcome, ${widget.user['name']}!',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (widget.user.containsKey('staffNo'))
                        Text('Staff No: ${widget.user['staffNo']}'),
                      SizedBox(height: 10),
                      Text('ICT602 MARK ENTRY SYSTEM',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SELECT STUDENT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 15),

                      if (_loadingStudents)
                        Center(child: CircularProgressIndicator())
                      else if (_students.isEmpty)
                        Center(child: Text('No students registered yet'))
                      else
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedStudent,
                          decoration: InputDecoration(
                            labelText: 'Choose Student',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_search),
                          ),
                          items: _students.map((student) {
                            return DropdownMenuItem(
                              value: student,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(student['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Matric: ${student['matricNo']}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() { _selectedStudent = value; }),
                          isExpanded: true,
                        ),
                    ],
                  ),
                ),
              ),

              if (_selectedStudent != null) ...[
                SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ENTER MARKS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 15),

                        TextField(
                          controller: _testMarkController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Test (out of 20)',
                            border: OutlineInputBorder(),
                            suffixText: '/20',
                          ),
                        ),
                        SizedBox(height: 10),

                        TextField(
                          controller: _assignmentMarkController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Assignment (out of 10)',
                            border: OutlineInputBorder(),
                            suffixText: '/10',
                          ),
                        ),
                        SizedBox(height: 10),

                        TextField(
                          controller: _projectMarkController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Project (out of 20)',
                            border: OutlineInputBorder(),
                            suffixText: '/20',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 30),

                ElevatedButton.icon(
                  onPressed: _saveMarksToFirestore,
                  icon: Icon(Icons.save),
                  label: Text('SAVE MARKS', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.green,
                  ),
                ),

                SizedBox(height: 10),

                OutlinedButton(
                  onPressed: _clearForm,
                  child: Text('CLEAR SELECTION'),
                ),
              ],

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
