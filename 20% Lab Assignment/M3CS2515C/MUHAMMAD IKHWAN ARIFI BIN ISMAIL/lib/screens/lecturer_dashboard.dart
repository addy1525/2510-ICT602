import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/user.dart';
import '../models/carry_mark.dart';
import 'login_screen.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({Key? key}) : super(key: key);

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  List<User> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => isLoading = true);
    students = await DatabaseHelper.instance.getAllStudents();
    setState(() => isLoading = false);
  }

  void _showEnterMarksDialog(User student) {
    final testController = TextEditingController();
    final assignmentController = TextEditingController();
    final projectController = TextEditingController();

    // Load existing marks if available
    DatabaseHelper.instance.getCarryMark(student.username).then((mark) {
      if (mark != null) {
        testController.text = mark.testMark.toString();
        assignmentController.text = mark.assignmentMark.toString();
        projectController.text = mark.projectMark.toString();
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Marks for ${student.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: testController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Test (Max: 20)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: assignmentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Assignment (Max: 10)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: projectController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Project (Max: 20)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final test = double.tryParse(testController.text) ?? 0;
              final assignment =
                  double.tryParse(assignmentController.text) ?? 0;
              final project = double.tryParse(projectController.text) ?? 0;

              if (test > 20 || assignment > 10 || project > 20) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Marks exceed maximum values!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final mark = CarryMark(
                studentUsername: student.username,
                testMark: test,
                assignmentMark: assignment,
                projectMark: project,
                studentName: student.fullName ?? student.username,
              );

              await DatabaseHelper.instance.insertCarryMark(mark);

              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Marks saved successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturer Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
          ? const Center(
              child: Text('No students found', style: TextStyle(fontSize: 18)),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Carry Marks for ICT602',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Test: 20% | Assignment: 10% | Project: 20%',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                student.fullName?[0] ?? 'S',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              student.fullName ?? student.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(student.username),
                            trailing: ElevatedButton.icon(
                              onPressed: () => _showEnterMarksDialog(student),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Enter Marks'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
