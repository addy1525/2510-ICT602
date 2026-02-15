import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnterMarksPage extends StatefulWidget {
  const EnterMarksPage({super.key});

  @override
  State<EnterMarksPage> createState() => _EnterMarksPageState();
}

class _EnterMarksPageState extends State<EnterMarksPage> {
  List<Map<String, dynamic>> students = [];
  bool loading = true;
  String searchQuery = '';
  String selectedCourse = 'Your Course';

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      students = [];
      for (var doc in query.docs) {
        final studentData = {
          'name': doc.data()['name'] ?? 'Unknown',
          'email': doc.data()['email'] ?? '',
          'password': doc.data()['password'] ?? '',
          ...doc.data()
        };
        
        // Fetch marks
        final marksDoc = await FirebaseFirestore.instance.collection('marks').doc(doc.id).get();
        if (marksDoc.exists) {
          studentData.addAll(marksDoc.data()!);
        } else {
          studentData.addAll({
            'test': 0.0, 
            'assignment': 0.0, 
            'project': 0.0,
            'lastUpdated': null
          });
        }
        students.add(studentData);
      }
      
      // Sort by name
      students.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      
    } catch (e) {
      print('Error fetching students: $e');
    }
    setState(() => loading = false);
  }

  List<Map<String, dynamic>> get filteredStudents {
    List<Map<String, dynamic>> filtered = students;
    
    // Filter by search
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((student) {
        final name = (student['name'] ?? '').toLowerCase();
        final email = (student['email'] ?? '').toLowerCase();
        final query = searchQuery.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }
    return filtered;
  }

  Future<void> showEditMarksDialog(Map<String, dynamic> student) async {
    final testCtl = TextEditingController(text: student['test'].toString());
    final assignCtl = TextEditingController(text: student['assignment'].toString());
    final projectCtl = TextEditingController(text: student['project'].toString());
    
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.blueAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Edit Marks",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  student['name'],
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  student['studentId'] ?? student['email'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Test Marks
                  _buildMarksInputField(
                    controller: testCtl,
                    label: "Test Marks",
                    maxMarks: 20,
                    icon: Icons.quiz,
                    color: Colors.blueAccent,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Assignment Marks
                  _buildMarksInputField(
                    controller: assignCtl,
                    label: "Assignment",
                    maxMarks: 10,
                    icon: Icons.assignment,
                    color: Colors.greenAccent,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Project Marks
                  _buildMarksInputField(
                    controller: projectCtl,
                    label: "Project",
                    maxMarks: 20,
                    icon: Icons.work,
                    color: Colors.orangeAccent,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Total Preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200] ?? Colors.grey),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Carry Marks:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _calculateTotal(testCtl.text, assignCtl.text, projectCtl.text),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  final test = double.tryParse(testCtl.text) ?? 0.0;
                  final assignment = double.tryParse(assignCtl.text) ?? 0.0;
                  final project = double.tryParse(projectCtl.text) ?? 0.0;
                  
                  if (test < 0 || test > 20 || assignment < 0 || assignment > 10 || project < 0 || project > 20) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Please enter valid marks (0-20 for test/project, 0-10 for assignment)"),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  
                  setState(() => isSaving = true);
                  
                  try {
                    await FirebaseFirestore.instance.collection('marks').doc(student['id']).set({
                      'test': test,
                      'assignment': assignment,
                      'project': project,
                      'lastUpdated': FieldValue.serverTimestamp(),
                      'updatedBy': FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseFirestore.instance.app.options.projectId), // You might want to get current lecturer ID
                    });
                    
                    await fetchStudents();
                    
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Updated marks for ${student['name']}"),
                          backgroundColor: Colors.greenAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Failed to update: $e"),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    setState(() => isSaving = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save, size: 20),
                          SizedBox(width: 8),
                          Text("Save Changes"),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMarksInputField({
    required TextEditingController controller,
    required String label,
    required double maxMarks,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Icon(icon, color: color),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "0 - $maxMarks",
                    suffixText: "/$maxMarks",
                    suffixStyle: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (_) {
                    // You could add real-time validation here
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _calculateTotal(String test, String assignment, String project) {
    final t = double.tryParse(test) ?? 0.0;
    final a = double.tryParse(assignment) ?? 0.0;
    final p = double.tryParse(project) ?? 0.0;
    return (t + a + p).toStringAsFixed(1);
  }

  Future<void> deleteMarks(String studentId, String studentName) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text("Confirm Delete"),
          ],
        ),
        content: Text("Delete all marks for $studentName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('marks').doc(studentId).delete();
        await fetchStudents();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Deleted marks for $studentName"),
            backgroundColor: Colors.greenAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.black87,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          "Manage Carry Marks",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: fetchStudents,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.refresh,
                color: Colors.blueAccent,
                size: 20,
              ),
            ),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.blueAccent,
              ),
            )
          : Column(
              children: [
                // Filters Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                            hintText: "Search by name, email, or ID...",
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stats Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blueAccent.withOpacity(0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(
                        "${filteredStudents.length}",
                        "Students",
                        Icons.people,
                      ),
                      _buildStatItem(
                        "${filteredStudents.where((s) => (s['test'] ?? 0) + (s['assignment'] ?? 0) + (s['project'] ?? 0) > 0).length}",
                        "With Marks",
                        Icons.check_circle,
                      ),
                      _buildStatItem(
                        "${filteredStudents.where((s) => (s['test'] ?? 0) + (s['assignment'] ?? 0) + (s['project'] ?? 0) == 0).length}",
                        "Pending",
                        Icons.pending,
                      ),
                    ],
                  ),
                ),
                
                // Students List
                Expanded(
                  child: filteredStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No students found",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                searchQuery.isNotEmpty
                                    ? "Try a different search term"
                                    : selectedCourse != 'All Courses'
                                        ? "No students in $selectedCourse"
                                        : "No students registered",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            final test = student['test'] ?? 0.0;
                            final assignment = student['assignment'] ?? 0.0;
                            final project = student['project'] ?? 0.0;
                            final total = test + assignment + project;
                            final hasMarks = total > 0;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Student Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                student['name'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                student['studentId']?.isNotEmpty == true
                                                    ? "${student['studentId']} • ${student['course'] ?? 'No Course'}"
                                                    : student['email'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: hasMarks 
                                                ? Colors.greenAccent.withOpacity(0.2)
                                                : Colors.orangeAccent.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            hasMarks ? "Graded" : "Pending",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: hasMarks ? Colors.greenAccent : Colors.orangeAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Marks Breakdown
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildMarkItem("Test", test, 20, Colors.blueAccent),
                                        _buildMarkItem("Assignment", assignment, 10, Colors.greenAccent),
                                        _buildMarkItem("Project", project, 20, Colors.orangeAccent),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Total & Actions
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Total",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blueAccent,
                                                ),
                                              ),
                                              Text(
                                                "${total.toStringAsFixed(1)}/50",
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Action Buttons
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () => showEditMarksDialog(student),
                                              icon: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.blueAccent.withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.edit,
                                                  color: Colors.blueAccent,
                                                  size: 20,
                                                ),
                                              ),
                                              tooltip: "Edit Marks",
                                            ),
                                            if (hasMarks)
                                              IconButton(
                                                onPressed: () => deleteMarks(student['id'], student['name']),
                                                icon: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.redAccent.withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.redAccent,
                                                    size: 20,
                                                  ),
                                                ),
                                                tooltip: "Delete Marks",
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blueAccent, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMarkItem(String label, double marks, double max, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "${marks.toStringAsFixed(1)}/$max",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}