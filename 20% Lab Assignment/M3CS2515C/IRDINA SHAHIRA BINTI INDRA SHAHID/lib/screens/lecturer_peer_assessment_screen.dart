import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ========== LECTURER PEER ASSESSMENT SCREEN ==========
class LecturerPeerAssessmentScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  LecturerPeerAssessmentScreen({required this.user});

  @override
  _LecturerPeerAssessmentScreenState createState() => _LecturerPeerAssessmentScreenState();
}

class _LecturerPeerAssessmentScreenState extends State<LecturerPeerAssessmentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      QuerySnapshot groupsSnapshot = await _firestore
          .collection('groups')
          .where('courseCode', isEqualTo: 'ICT602')
          .get();

      List<Map<String, dynamic>> groups = [];
      for (var doc in groupsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        groups.add({
          'id': doc.id,
          ...data,
        });
      }

      setState(() {
        _groups = groups;
        _loading = false;
      });

    } catch (e) {
      print('Error loading groups: $e');
      setState(() => _loading = false);
    }
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    double averageRating = 0;
    int totalAssessments = 0;

    if (group.containsKey('peerAssessmentAverages') && group['peerAssessmentAverages'] is Map) {
      Map<String, dynamic> averages = group['peerAssessmentAverages'];
      if (averages.isNotEmpty) {
        double sum = averages.values.reduce((a, b) => a + b);
        averageRating = sum / averages.length;
      }
    }

    totalAssessments = group['totalAssessments'] ?? 0;
    return Card(
    child: Padding(
    padding: const EdgeInsets.all(15),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(group['name'] ?? 'Unnamed Group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    if (group.containsKey('projectTitle'))
    Text('Project: ${group['projectTitle']}'),
    SizedBox(height: 10),
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Text('Members: ${(group['members'] as List).length}'),
    Chip(
    label: Text('${totalAssessments} assessments'),
    backgroundColor: Colors.blue[50],
    ),
    ],
    ),
    SizedBox(height: 10),
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Text('Average Rating:'),
    Text('${averageRating.toStringAsFixed(1)}/10',
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
    color: _getRatingColor(averageRating))),
    ],
    ),
    SizedBox(height: 10),
    ElevatedButton(
    onPressed: () => _viewGroupDetails(group),
    child: Text('View Details'),
    style: ElevatedButton.styleFrom(
    minimumSize: Size(double.infinity, 40),
    ),
    ),
    ],
    ),
    ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8) return Colors.green;
    if (rating >= 6) return Colors.blue;
    if (rating >= 4) return Colors.orange;
    return Colors.red;
  }

  void _viewGroupDetails(Map<String, dynamic> group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Group Details: ${group['name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (group.containsKey('projectTitle'))
                Text('Project: ${group['projectTitle']}'),
              SizedBox(height: 10),
              Text('Members:', style: TextStyle(fontWeight: FontWeight.bold)),
              for (var member in (group['members'] as List))
                Text('  • $member'),
              SizedBox(height: 10),
              if (group.containsKey('peerAssessmentAverages'))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Individual Ratings:', style: TextStyle(fontWeight: FontWeight.bold)),
                    for (var entry in (group['peerAssessmentAverages'] as Map<String, dynamic>).entries)
                      Text('  • ${entry.key}: ${entry.value.toStringAsFixed(1)}/10'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Peer Assessment Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadGroups,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              color: Colors.purple[50],
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Icon(Icons.group_work, size: 50, color: Colors.purple),
                    SizedBox(height: 10),
                    Text('Peer Assessment Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('ICT602 - Fundamentals of Software Development'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            if (_groups.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.group, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('No groups found', style: TextStyle(fontSize: 16)),
                      Text('Create groups in Firestore first', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              ..._groups.map((group) => Column(
                children: [
                  _buildGroupCard(group),
                  SizedBox(height: 15),
                ],
              )).toList(),
          ],
        ),
      ),
    );
  }
}


