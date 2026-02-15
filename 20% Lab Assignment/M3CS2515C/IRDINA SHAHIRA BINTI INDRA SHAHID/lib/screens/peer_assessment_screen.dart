import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ict602_app/services/notification_service.dart';

// ========== PEER ASSESSMENT SCREEN  ==========
class PeerAssessmentScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  PeerAssessmentScreen({required this.user});

  @override
  _PeerAssessmentScreenState createState() => _PeerAssessmentScreenState();
}

class _PeerAssessmentScreenState extends State<PeerAssessmentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _groupMembers = [];
  Map<String, double> _ratings = {};
  Map<String, String> _comments = {};
  bool _loading = true;
  bool _submitted = false;
  String _groupId = '';
  Map<String, dynamic>? _groupInfo;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      String matricNo = widget.user['matricNo'];

      // Check if student has a group
      QuerySnapshot groupSnapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: matricNo)
          .get();

      if (groupSnapshot.docs.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      var groupDoc = groupSnapshot.docs.first;
      _groupId = groupDoc.id;
      _groupInfo = groupDoc.data() as Map<String, dynamic>;
      List<dynamic> members = groupDoc['members'];

      // Load member details
      List<Map<String, dynamic>> groupMembers = [];

      for (var matric in members) {
        if (matric != matricNo) { // Exclude self
          QuerySnapshot studentQuery = await _firestore
              .collection('users')
              .where('matricNo', isEqualTo: matric)
              .limit(1)
              .get();

          if (studentQuery.docs.isNotEmpty) {
            var studentDoc = studentQuery.docs.first;
            Map<String, dynamic> student = studentDoc.data() as Map<String, dynamic>;

            groupMembers.add({
              'uid': studentDoc.id,
              'name': student['name'],
              'matricNo': student['matricNo'],
              'email': student['email'],
            });

            _ratings[matric] = 5.0;
            _comments[matric] = '';
          }
        }
      }

      // Check if already submitted
      DocumentSnapshot assessmentDoc = await _firestore
          .collection('peer_assessments')
          .doc('${_groupId}_${matricNo}')
          .get();

    if (assessmentDoc.exists) {
    Map<String, dynamic> data = assessmentDoc.data() as Map<String, dynamic>;
    if (data['submitted'] == true) {
    _submitted = true;
    for (var member in groupMembers) {
    String otherMatric = member['matricNo'];
    if (data['ratings'] != null && data['ratings'][otherMatric] != null) {
    _ratings[otherMatric] = (data['ratings'][otherMatric] as num).toDouble();
    }
    if (data['comments'] != null && data['comments'][otherMatric] != null) {
    _comments[otherMatric] = data['comments'][otherMatric];
    }
    }
    }
    }

    setState(() {
    _groupMembers = groupMembers;
    _loading = false;
    });

    } catch (e) {
    print('Error loading group data: $e');
    setState(() => _loading = false);
    }
  }

  Future<void> _submitAssessment() async {
    try {
      String matricNo = widget.user['matricNo'];
      String assessmentId = '${_groupId}_${matricNo}';

      double averageRating = _calculateAverageRating();

      Map<String, dynamic> assessmentData = {
        'id': assessmentId,
        'assessorMatric': matricNo,
        'assessorName': widget.user['name'],
        'assessorUid': widget.user['uid'],
        'groupId': _groupId,
        'groupName': _groupInfo?['name'] ?? 'Group $_groupId',
        'ratings': _ratings,
        'comments': _comments,
        'averageRating': averageRating,
        'submitted': true,
        'submittedAt': FieldValue.serverTimestamp(),
        'courseCode': 'ICT602',
      };

      await _firestore
          .collection('peer_assessments')
          .doc(assessmentId)
          .set(assessmentData);

      await _updateGroupStatistics();

      setState(() => _submitted = true);

      await _notifyLecturer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Peer assessment submitted successfully!')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateGroupStatistics() async {
    try {
      QuerySnapshot assessments = await _firestore
          .collection('peer_assessments')
          .where('groupId', isEqualTo: _groupId)
          .where('submitted', isEqualTo: true)
          .get();

      if (assessments.docs.isEmpty) return;

      Map<String, List<double>> memberRatings = {};
      int totalAssessments = assessments.docs.length;

      for (var doc in assessments.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> ratings = data['ratings'];

        ratings.forEach((matric, rating) {
          if (!memberRatings.containsKey(matric)) {
            memberRatings[matric] = [];
          }
          memberRatings[matric]!.add((rating as num).toDouble());
        });
      }

      Map<String, double> finalAverages = {};
      memberRatings.forEach((matric, ratings) {
        double average = ratings.reduce((a, b) => a + b) / ratings.length;
        finalAverages[matric] = average;
      });

      await _firestore
          .collection('groups')
          .doc(_groupId)
          .update({
        'peerAssessmentAverages': finalAverages,
        'totalAssessments': totalAssessments,
        'lastCalculated': FieldValue.serverTimestamp(),
      });

      print('✅ Group statistics updated');

    } catch (e) {
      print('Error updating group statistics: $e');
    }
  }

  Future<void> _notifyLecturer() async {
    try {
      QuerySnapshot lecturers = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'lecturer')
          .limit(1)
          .get();

      if (lecturers.docs.isNotEmpty) {
        var lecturer = lecturers.docs.first;

    await NotificationService.sendNotificationToUser(
    userId: lecturer.id,
    title: '📝 Peer Assessment Submitted',
    body: '${widget.user['name']} has submitted peer assessment for group ${_groupInfo?['name'] ?? _groupId}',
    type: 'peer_assessment',
    data: {
    'groupId': _groupId,
    'studentName': widget.user['name'],
    'studentMatric': widget.user['matricNo'],
    'courseCode': 'ICT602',
    },
    );
    }

    } catch (e) {
    print('Error notifying lecturer: $e');
    }
  }

  double _calculateAverageRating() {
    if (_ratings.isEmpty) return 0;
    double sum = _ratings.values.reduce((a, b) => a + b);
    return sum / _ratings.length;
  }

  Widget _buildGroupInfo() {
    if (_groupInfo == null) return SizedBox();

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GROUP INFORMATION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            SizedBox(height: 10),
            Text('Group: ${_groupInfo!['name'] ?? 'Group $_groupId'}'),
            if (_groupInfo!.containsKey('projectTitle'))
              Text('Project: ${_groupInfo!['projectTitle']}'),
            Text('Total Members: ${_groupMembers.length + 1}'),
            if (_groupInfo!.containsKey('peerAssessmentAverages'))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Text('Group Average Rating: ${(_groupInfo!['peerAssessmentAverages'] as Map<String, dynamic>).values.reduce((a, b) => a + b) / (_groupInfo!['peerAssessmentAverages'] as Map<String, dynamic>).length}'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> member) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.person, size: 30),
                ),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Matric: ${member['matricNo']}', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),

            SizedBox(height: 20),

            Text('Teamwork & Contribution', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            Slider(
              value: _ratings[member['matricNo']] ?? 5.0,
              min: 1,
              max: 10,
              divisions: 9,
              label: '${_ratings[member['matricNo']]?.toStringAsFixed(1)}/10',
              onChanged: _submitted ? null : (value) {
                setState(() {
                  _ratings[member['matricNo']] = value;
                });
              },
            ),

            SizedBox(height: 15),

            Text('Comments (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            TextField(
              controller: TextEditingController(text: _comments[member['matricNo']] ?? ''),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Provide constructive feedback...',
                border: OutlineInputBorder(),
                enabled: !_submitted,
              ),
              onChanged: !_submitted ? (value) {
                _comments[member['matricNo']] = value;
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Peer Assessment'),
        actions: [
          if (_submitted)
            Chip(label: Text('Submitted', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildGroupInfo(),

            SizedBox(height: 20),

            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📝 Peer Assessment Guidelines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text('• Rate each team member fairly (1-10)'),
                    Text('• Focus on teamwork, contribution, and reliability'),
                    Text('• Provide constructive comments'),
                    Text('• Assessments are anonymous to other students'),
                    Text('• Once submitted, cannot be changed'),
                    SizedBox(height: 10),
                    if (_submitted)
                      Text('✅ You have already submitted your assessment', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            if (_groupMembers.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.group, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('No group members found', style: TextStyle(fontSize: 16)),
                      Text('Please contact your lecturer to be assigned to a group', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              ..._groupMembers.map((member) => Column(
                children: [
                  _buildRatingCard(member),
                  SizedBox(height: 20),
                ],
              )).toList(),

            if (_groupMembers.isNotEmpty && !_submitted)
              ElevatedButton.icon(
                onPressed: _submitAssessment,
                icon: Icon(Icons.send),
                label: Text('SUBMIT PEER ASSESSMENT'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                ),
              ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
