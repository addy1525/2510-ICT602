import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ========== ANALYTICS SCREEN ==========
class AnalyticsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  AnalyticsScreen({required this.user});

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _allMarks = [];
  List<Map<String, dynamic>> _allStudents = [];
  bool _loading = true;

  double _classAverage = 0;
  double _median = 0;
  double _highest = 0;
  double _lowest = 0;
  int _totalStudents = 0;
  Map<String, int> _gradeDistribution = {};
  Map<String, double> _componentAverages = {
    'test': 0,
    'assignment': 0,
    'project': 0
  };

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      setState(() => _loading = true);

      // 1. Load all students dengan case-insensitive
      QuerySnapshot allUsers = await _firestore
          .collection('users')
          .get();

      // Filter manual untuk handle case sensitivity
      _allStudents = allUsers.docs.where((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('role')) {
          String role = data['role'].toString().toLowerCase();
          return role.contains('student');
        }
        return false;
      }).map((doc) {
        return {
          'uid': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      // 2. Load all marks
      QuerySnapshot marksSnapshot = await _firestore
          .collection('carry_marks')
          .where('courseCode', isEqualTo: 'ICT602')
          .get();

      if (marksSnapshot.docs.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      List<Map<String, dynamic>> marks = [];
      List<double> allMarks = [];
      double totalTest = 0, totalAssignment = 0, totalProject = 0;
      int count = 0;

      for (var doc in marksSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double testMark = (data['test'] ?? 0).toDouble();
        double assignmentMark = (data['assignment'] ?? 0).toDouble();
        double projectMark = (data['project'] ?? 0).toDouble();
        double totalCarry = (data['totalCarry'] ?? 0).toDouble();

        // Find student info
        String matricNo = data['matricNo'];
        var student = _allStudents.firstWhere(
              (s) => s['matricNo'] == matricNo,
          orElse: () => {'name': 'Unknown', 'matricNo': matricNo},
        );

        marks.add({
          'name': student['name'],
          'matricNo': matricNo,
          'test': testMark,
          'assignment': assignmentMark,
          'project': projectMark,
          'carryMark': totalCarry,
          'percentage': (totalCarry / 50) * 100,
          'grade': _calculateGrade(totalCarry),
        });

        allMarks.add(totalCarry);
        totalTest += testMark;
        totalAssignment += assignmentMark;
        totalProject += projectMark;
        count++;
      }

      // Calculate component averages
      if (count > 0) {
        _componentAverages['test'] = totalTest / count;
        _componentAverages['assignment'] = totalAssignment / count;
        _componentAverages['project'] = totalProject / count;
      }

      // Calculate statistics
      _calculateStatistics(allMarks, marks);

      setState(() {
        _allMarks = marks;
        _loading = false;
      });

    } catch (e) {
      print('Analytics error: $e');
      setState(() => _loading = false);
    }
  }

  void _calculateStatistics(List<double> marks, List<Map<String, dynamic>> students) {
    if (marks.isEmpty) return;

    marks.sort();
    double sum = marks.reduce((a, b) => a + b);

    _classAverage = sum / marks.length;
    _totalStudents = marks.length;
    _highest = marks.last;
    _lowest = marks.first;

    // Median
    if (marks.length % 2 == 1) {
    _median = marks[marks.length ~/ 2];
    } else {
    _median = (marks[marks.length ~/ 2 - 1] + marks[marks.length ~/ 2]) / 2;
    }

    // Grade distribution
    _gradeDistribution = {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0};
    for (var student in students) {
    String grade = student['grade'];
    if (_gradeDistribution.containsKey(grade)) {
    _gradeDistribution[grade] = _gradeDistribution[grade]! + 1;
    }
    }
  }

  String _calculateGrade(double carryMark) {
    double percentage = (carryMark / 50) * 100;
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  Widget _buildStatsCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: Colors.grey, fontSize: 12)),
            SizedBox(height: 5),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('COMPONENT AVERAGES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Test:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_componentAverages['test']!.toStringAsFixed(1)}/20'),
              ],
            ),
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: _componentAverages['test']! / 20,
              backgroundColor: Colors.grey[200],
              color: Colors.blue,
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Assignment:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_componentAverages['assignment']!.toStringAsFixed(1)}/10'),
              ],
            ),
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: _componentAverages['assignment']! / 10,
              backgroundColor: Colors.grey[200],
              color: Colors.green,
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Project:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_componentAverages['project']!.toStringAsFixed(1)}/20'),
              ],
            ),
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: _componentAverages['project']! / 20,
              backgroundColor: Colors.grey[200],
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeDistribution() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GRADE DISTRIBUTION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            for (var entry in _gradeDistribution.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      child: Text('${entry.key}:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _totalStudents > 0 ? entry.value / _totalStudents : 0,
                        backgroundColor: Colors.grey[200],
                        color: _getGradeColor(entry.key),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('${entry.value} students', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A': return Colors.green;
      case 'B': return Colors.blue;
      case 'C': return Colors.orange;
      case 'D': return Colors.purple;
      case 'F': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grade Analytics'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _buildStatsCard('CLASS AVERAGE', '${_classAverage.toStringAsFixed(1)}/50', Colors.blue),
                _buildStatsCard('MEDIAN SCORE', '${_median.toStringAsFixed(1)}/50', Colors.green),
                _buildStatsCard('HIGHEST SCORE', '${_highest.toStringAsFixed(1)}/50', Colors.green),
                _buildStatsCard('LOWEST SCORE', '${_lowest.toStringAsFixed(1)}/50', Colors.red),
              ],
            ),

            SizedBox(height: 20),

            _buildComponentStats(),

            SizedBox(height: 20),

            _buildGradeDistribution(),

            SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STUDENT PERFORMANCE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    if (_allMarks.isEmpty)
                      Center(child: Text('No marks data available'))
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('Student')),
                            DataColumn(label: Text('Matric')),
                            DataColumn(label: Text('Test')),
                            DataColumn(label: Text('Assignment')),
                            DataColumn(label: Text('Project')),
                            DataColumn(label: Text('Total')),
                            DataColumn(label: Text('Grade')),
                          ],
                          rows: _allMarks.map((student) {
                            return DataRow(cells: [
                              DataCell(
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    student['name'],
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(Text(student['matricNo'])),
                              DataCell(Text('${student['test'].toStringAsFixed(1)}/20')),
                              DataCell(Text('${student['assignment'].toStringAsFixed(1)}/10')),
                              DataCell(Text('${student['project'].toStringAsFixed(1)}/20')),
                              DataCell(Text('${student['carryMark'].toStringAsFixed(1)}/50')),
                              DataCell(
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getGradeColor(student['grade']).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _getGradeColor(student['grade'])),
                                  ),
                                  child: Text(student['grade'], style: TextStyle(
                                    color: _getGradeColor(student['grade']),
                                    fontWeight: FontWeight.bold,
                                  )),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () => _exportAnalytics(),
              icon: Icon(Icons.download),
              label: Text('EXPORT ANALYTICS REPORT'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAnalytics() async {
    String csv = 'Student Name,Matric No,Test,Assignment,Project,Total Carry,Percentage,Grade\n';
    for (var student in _allMarks) {
      csv += '"${student['name']}","${student['matricNo']}",${student['test']},${student['assignment']},${student['project']},${student['carryMark']},${student['percentage']},${student['grade']}\n';
    }

    csv += '\nSUMMARY\n';
    csv += 'Total Students,$_totalStudents\n';
    csv += 'Class Average,${_classAverage.toStringAsFixed(1)}\n';
    csv += 'Median,${_median.toStringAsFixed(1)}\n';
    csv += 'Highest,${_highest.toStringAsFixed(1)}\n';
    csv += 'Lowest,${_lowest.toStringAsFixed(1)}\n';
    csv += 'Test Average,${_componentAverages['test']!.toStringAsFixed(1)}\n';
    csv += 'Assignment Average,${_componentAverages['assignment']!.toStringAsFixed(1)}\n';
    csv += 'Project Average,${_componentAverages['project']!.toStringAsFixed(1)}\n';

    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Analytics report generated (${_totalStudents} students)')),
    );
  }
}