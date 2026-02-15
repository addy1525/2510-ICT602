import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ict602_app/services/notification_service.dart';

// ========== ATTENDANCE SCREEN  ==========
class AttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  AttendanceScreen({required this.user});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _students = [];
  Map<String, bool> _attendanceStatus = {};
  DateTime _selectedDate = DateTime.now();
  String _selectedSession = 'Lecture';
  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _attendanceHistory = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadExistingAttendance();
    _loadAttendanceHistory();
  }

  Future<void> _loadStudents() async {
    try {
      QuerySnapshot allUsers = await _firestore
          .collection('users')
          .get();

      List<Map<String, dynamic>> students = [];
      for (var doc in allUsers.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        // Check if student dengan case-insensitive
        if (userData.containsKey('role')) {
          String role = userData['role'].toString().toLowerCase();
          if (role.contains('student')) {
            students.add({
              'uid': doc.id,
              'name': userData['name'],
              'matricNo': userData['matricNo'],
              'email': userData['email'],
            });

            _attendanceStatus[userData['matricNo']] = true;
          }
        }
      }

      // Sort by name
      students.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

      setState(() {
        _students = students;
      });

    } catch (e) {
      print('Error loading students: $e');
    }
  }

  Future<void> _loadExistingAttendance() async {
    try {
      String dateKey = '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';

      DocumentSnapshot attendanceDoc = await _firestore
          .collection('attendance')
          .doc('ICT602_${dateKey}_${_selectedSession}')
          .get();

      if (attendanceDoc.exists) {
        Map<String, dynamic> data = attendanceDoc.data() as Map<String, dynamic>;
        if (data['records'] != null) {
          Map<String, dynamic> records = data['records'];
          setState(() {
            records.forEach((matric, status) {
              _attendanceStatus[matric] = status == 'present';
            });
          });
        }
      }
    } catch (e) {
      print('Error loading attendance: $e');
    }
  }

  Future<void> _loadAttendanceHistory() async {
    try {
      QuerySnapshot historySnapshot = await _firestore
          .collection('attendance')
          .where('courseCode', isEqualTo: 'ICT602')
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> history = [];
      for (var doc in historySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        history.add({
          'id': doc.id,
          ...data,
        });
      }

      setState(() {
        _attendanceHistory = history;
        _loading = false;
      });

    } catch (e) {
      print('Error loading history: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _saving = true);

    try {
      User? lecturer = FirebaseAuth.instance.currentUser;
      if (lecturer == null) throw Exception('Not authenticated');

      String dateKey = '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';
      String docId = 'ICT602_${dateKey}_${_selectedSession}';

      Map<String, String> records = {};
      List<String> absentStudents = [];

      _attendanceStatus.forEach((matric, present) {
        records[matric] = present ? 'present' : 'absent';
        if (!present) absentStudents.add(matric);
      });

      int presentCount = _attendanceStatus.values.where((status) => status).length;
      int totalCount = _attendanceStatus.length;
      double attendanceRate = (presentCount / totalCount) * 100;

      await _firestore
          .collection('attendance')
          .doc(docId)
          .set({
        'id': docId,
        'courseCode': 'ICT602',
        'date': Timestamp.fromDate(_selectedDate),
        'dateKey': dateKey,
        'session': _selectedSession,
        'records': records,
        'lecturerUid': lecturer.uid,
        'lecturerName': widget.user['name'],
        'lecturerStaffNo': widget.user['staffNo'],
        'totalStudents': totalCount,
        'presentCount': presentCount,
        'absentCount': totalCount - presentCount,
        'attendanceRate': attendanceRate,
        'absentStudents': absentStudents,
        'takenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      for (var matric in _attendanceStatus.keys) {
        String studentDocId = 'ICT602_${matric}';

        await _firestore
            .collection('student_attendance')
            .doc(studentDocId)
            .set({
          'matricNo': matric,
          'courseCode': 'ICT602',
          'studentName': _students
              .firstWhere((s) => s['matricNo'] == matric, orElse: () => {'name': 'Unknown'})['name'],
          'records': FieldValue.arrayUnion([{
            'date': Timestamp.fromDate(_selectedDate),
            'session': _selectedSession,
            'status': (_attendanceStatus[matric] ?? true) ? 'present' : 'absent',
            'attendanceId': docId,
          }]),
          'totalClasses': FieldValue.increment(1),
          'presentClasses': FieldValue.increment((_attendanceStatus[matric] ?? true) ? 1 : 0),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await _notifyAbsentStudents(absentStudents, dateKey);

      await _loadAttendanceHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance saved successfully! ($presentCount/$totalCount present)'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _saving = false);
  }

  Future<void> _notifyAbsentStudents(List<String> absentMatrics, String dateKey) async {
    try {
      if (absentMatrics.isEmpty) return;

      for (var matric in absentMatrics) {
        var student = _students.firstWhere(
              (s) => s['matricNo'] == matric,
          orElse: () => {'uid': '', 'name': 'Student'},
        );

        if (student['uid'] != null && student['uid'].isNotEmpty) {
          await NotificationService.sendNotificationToUser(
            userId: student['uid'],
            title: '⚠️ Attendance Alert',
            body: 'You were marked absent for ICT602 ${_selectedSession} on ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            type: 'attendance',
            data: {
              'date': dateKey,
              'session': _selectedSession,
              'status': 'absent',
              'courseCode': 'ICT602',
              'lecturerName': widget.user['name'],
            },
          );
        }
      }

      print('✅ Notified ${absentMatrics.length} absent students');

    } catch (e) {
      print('❌ Error notifying absent students: $e');
    }
  }

  Widget _buildStudentAttendanceRow(Map<String, dynamic> student) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          child: Icon(Icons.person),
        ),
        title: Text(student['name'], style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Matric: ${student['matricNo']}'),
        trailing: Switch(
          value: _attendanceStatus[student['matricNo']] ?? true,
          onChanged: (value) {
            setState(() {
              _attendanceStatus[student['matricNo']] = value;
            });
          },
          activeColor: Colors.green,
          inactiveTrackColor: Colors.red[200],
        ),
      ),
    );
  }

  Widget _buildAttendanceHistoryCard(Map<String, dynamic> record) {
    DateTime date = (record['date'] as Timestamp).toDate();
    double rate = (record['attendanceRate'] ?? 0).toDouble();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAttendanceColor(rate),
          child: Text(
            '${rate.toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('${record['session']} - ${date.day}/${date.month}/${date.year}'),
        subtitle: Text('${record['presentCount']}/${record['totalStudents']} students present'),
        trailing: Chip(
          label: Text('${record['absentCount']} absent'),
          backgroundColor: Colors.red[50],
        ),
        onTap: () {
          _viewAttendanceDetails(record);
        },
      ),
    );
  }

  void _viewAttendanceDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Attendance Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date: ${(record['date'] as Timestamp).toDate().day}/${(record['date'] as Timestamp).toDate().month}/${(record['date'] as Timestamp).toDate().year}'),
              Text('Session: ${record['session']}'),
              Text('Lecturer: ${record['lecturerName']}'),
              SizedBox(height: 10),
              Divider(),
              Text('Statistics:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Total Students: ${record['totalStudents']}'),
              Text('• Present: ${record['presentCount']}'),
              Text('• Absent: ${record['absentCount']}'),
              Text('• Rate: ${(record['attendanceRate'] ?? 0).toStringAsFixed(1)}%'),
              SizedBox(height: 10),
              if (record['absentStudents'] != null && (record['absentStudents'] as List).isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Absent Students:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    for (var matric in (record['absentStudents'] as List).take(5))
                      Text('  • $matric'),
                    if ((record['absentStudents'] as List).length > 5)
                      Text('  ... and ${(record['absentStudents'] as List).length - 5} more'),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getAttendanceColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 80) return Colors.blue;
    if (rate >= 70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Management'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2025),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDate = picked;
                                });
                                _loadExistingAttendance();
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSession,
                            decoration: InputDecoration(
                              labelText: 'Session',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.schedule),
                            ),
                            items: ['Lecture', 'Tutorial', 'Lab'].map((session) {
                              return DropdownMenuItem(
                                value: session,
                                child: Text(session),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedSession = value!);
                              _loadExistingAttendance();
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _attendanceStatus.forEach((key, value) {
                                  _attendanceStatus[key] = true;
                                });
                              });
                            },
                            icon: Icon(Icons.check_circle),
                            label: Text('Mark All Present'),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _attendanceStatus.forEach((key, value) {
                                  _attendanceStatus[key] = false;
                                });
                              });
                            },
                            icon: Icon(Icons.cancel),
                            label: Text('Mark All Absent'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Text('ATTENDANCE SUMMARY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text('Total', style: TextStyle(color: Colors.grey)),
                            Text('${_students.length}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('Present', style: TextStyle(color: Colors.grey)),
                            Text(
                              '${_attendanceStatus.values.where((status) => status).length}',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text('Absent', style: TextStyle(color: Colors.grey)),
                            Text(
                              '${_attendanceStatus.values.where((status) => !status).length}',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STUDENT ATTENDANCE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    ..._students.map(_buildStudentAttendanceRow).toList(),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RECENT ATTENDANCE HISTORY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    if (_attendanceHistory.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 60, color: Colors.grey),
                            SizedBox(height: 10),
                            Text('No attendance records yet'),
                          ],
                        ),
                      )
                    else
                      ..._attendanceHistory.map(_buildAttendanceHistoryCard).toList(),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            _saving
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              onPressed: _saveAttendance,
              icon: Icon(Icons.save),
              label: Text('SAVE ATTENDANCE'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}