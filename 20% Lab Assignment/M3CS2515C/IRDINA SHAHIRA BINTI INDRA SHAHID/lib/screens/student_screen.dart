import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_notification_screen.dart';
import 'peer_assessment_screen.dart';
import 'welcome_screen.dart';

// ========== STUDENT SCREEN ==========
class StudentScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const StudentScreen({super.key, required this.user});

  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _carryMarkController = TextEditingController();
  double _test = 0;
  double _assignment = 0;
  double _project = 0;
  double _totalCarry = 0;
  double _carryPercent = 0;
  String _selectedGrade = 'A (80-89)';
  double _requiredFinalExam = 0.0;
  bool _showResult = false;
  bool _isImpossible = false;
  bool _loadingMarks = true;
  String _marksStatus = 'Loading marks...';

  final Map<String, double> _gradeRanges = {
    'A+ (90-100)': 95,
    'A (80-89)': 84.5,
    'A- (75-79)': 77,
    'B+ (70-74)': 72,
    'B (65-69)': 67,
    'B- (60-64)': 62,
    'C+ (55-59)': 57,
    'C (50-54)': 52,
  };
  @override
  void initState() {
    super.initState();
    _loadStudentMarks();
  }

  void _loadStudentMarks() async {
    try {
      setState(() {
        _loadingMarks = true;
        _marksStatus = 'Loading marks...';
      });

      String matricNo = widget.user['matricNo'];

      DocumentSnapshot doc = await _firestore
          .collection('carry_marks')
          .doc(matricNo)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        setState(() {
          _test = (data['test'] ?? 0).toDouble();
          _assignment = (data['assignment'] ?? 0).toDouble();
          _project = (data['project'] ?? 0).toDouble();
          _totalCarry = _test + _assignment + _project;
          _carryPercent = (_totalCarry / 50) * 100;
          _carryMarkController.text = _totalCarry.toStringAsFixed(1);
          _loadingMarks = false;
          _marksStatus = 'Marks loaded';
        });

      } else {
        setState(() {
          _loadingMarks = false;
          _marksStatus = 'No marks yet';
          _carryMarkController.text = '0';
        });
      }
    } catch (e) {
      setState(() {
        _loadingMarks = false;
        _marksStatus = 'Error loading marks';
        _carryMarkController.text = '0';
      });
    }
  }

  void _calculateRequiredMark() {
    double carryMark = double.tryParse(_carryMarkController.text) ?? -1;

    if (carryMark < 0 || carryMark > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Carry mark must be between 0 and 50'), backgroundColor: Colors.red),
      );
      return;
    }

    double carryWeight = (carryMark / 50) * 50;
    double targetPercent = _gradeRanges[_selectedGrade]!;
    double requiredFinalPercent = targetPercent - carryWeight;

    if (requiredFinalPercent > 50) {
      _isImpossible = true;
      _requiredFinalExam = 50;
    } else if (requiredFinalPercent < 0) {
      _isImpossible = false;
      _requiredFinalExam = 0;
    } else {
      _isImpossible = false;
      _requiredFinalExam = requiredFinalPercent;
    }

    setState(() {
      _showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Panel'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStudentMarks,
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StudentNotificationScreen(user: widget.user)),
            ),
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
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [
                    Icon(Icons.person, size: 60, color: Colors.blue),
                    SizedBox(height: 10),
                    Text(
                      'Welcome, ${widget.user['name']}!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text('Matric: ${widget.user['matricNo']}'),
                    SizedBox(height: 10),
                    Text(
                      'ICT602 GRADE CALCULATOR',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    SizedBox(height: 10),
                    Text(_marksStatus, style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            Card(
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR CARRY MARKS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                    SizedBox(height: 15),

                    if (_loadingMarks)
                      Center(child: CircularProgressIndicator())
                    else ...[
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Test:"), Text("$_test / 20", style: TextStyle(fontWeight: FontWeight.bold))]),
                      SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Assignment:"), Text("$_assignment / 10", style: TextStyle(fontWeight: FontWeight.bold))]),
                      SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Project:"), Text("$_project / 20", style: TextStyle(fontWeight: FontWeight.bold))]),
                      Divider(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text("Total Carry:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("$_totalCarry / 50", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                      ]),
                      SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text("Carry Percentage:"),
                        Text("${_carryPercent.toStringAsFixed(1)}%", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                      ]),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            Card(
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GRADE CALCULATOR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    TextField(
                      controller: _carryMarkController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Carry Mark (out of 50)',
                        border: OutlineInputBorder(),
                        suffixText: '/50',
                      ),
                      onChanged: (value) => setState(() { _showResult = false; }),
                    ),
                    SizedBox(height: 20),
                    Text('SELECT TARGET GRADE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedGrade,
                      decoration: InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.grade)),
                      items: _gradeRanges.keys.map((grade) => DropdownMenuItem(value: grade, child: Text(grade))).toList(),
                      onChanged: (value) => setState(() { _selectedGrade = value!; _showResult = false; }),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _calculateRequiredMark,
                      icon: Icon(Icons.calculate),
                      label: Text('CALCULATE REQUIRED FINAL EXAM'),
                      style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), backgroundColor: Colors.green),
                    ),
                  ],
                ),
              ),
            ),

            if (_showResult) ...[
              SizedBox(height: 20),
              Card(
                color: _isImpossible ? Colors.red[50] : Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('CALCULATION RESULT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 15),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Your Carry Mark:'), Text('${_carryMarkController.text}/50', style: TextStyle(fontWeight: FontWeight.bold))]),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Target Grade:'), Text(_selectedGrade, style: TextStyle(fontWeight: FontWeight.bold))]),
                      Divider(height: 30),
                      Text('REQUIRED FINAL EXAM MARK:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Text('${_requiredFinalExam.toStringAsFixed(1)}/50', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _isImpossible ? Colors.red : Colors.green)),
                      SizedBox(height: 15),
                      Card(
                        color: _isImpossible ? Colors.red : Colors.green,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.white),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _isImpossible ? '⚠️ Impossible to achieve target grade' :
                                  _requiredFinalExam >= 40 ? '🎯 Challenging - Need to study hard' :
                                  _requiredFinalExam >= 25 ? '📚 Achievable with good preparation' : '✅ Easily achievable',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PeerAssessmentScreen(user: widget.user),
                    ),
                  ),
                  icon: Icon(Icons.group),
                  label: Text('Peer Assessment'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Check notifications for attendance updates!')),
                    );
                  },
                  icon: Icon(Icons.event_note),
                  label: Text('My Attendance'),
                ),
              ],
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}