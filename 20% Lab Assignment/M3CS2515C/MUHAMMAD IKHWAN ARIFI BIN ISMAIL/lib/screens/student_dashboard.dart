import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/user.dart';
import '../models/carry_mark.dart';
import '../widgets/grade_calculator.dart';
import 'login_screen.dart';

class StudentDashboard extends StatefulWidget {
  final User student;

  const StudentDashboard({Key? key, required this.student}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  CarryMark? carryMark;
  bool isLoading = true;
  String selectedGrade = 'A+';

  final Map<String, Map<String, dynamic>> gradeRanges = {
    'A+': {'min': 90, 'max': 100},
    'A': {'min': 80, 'max': 89},
    'A-': {'min': 75, 'max': 79},
    'B+': {'min': 70, 'max': 74},
    'B': {'min': 65, 'max': 69},
    'B-': {'min': 60, 'max': 64},
    'C+': {'min': 55, 'max': 59},
    'C': {'min': 50, 'max': 54},
  };

  @override
  void initState() {
    super.initState();
    _loadCarryMark();
  }

  Future<void> _loadCarryMark() async {
    setState(() => isLoading = true);
    carryMark = await DatabaseHelper.instance.getCarryMark(
      widget.student.username,
    );
    setState(() => isLoading = false);
  }

  double calculateRequiredExamMark(String grade) {
    if (carryMark == null) return 0;

    final gradeInfo = gradeRanges[grade]!;
    final minTotalMark = gradeInfo['min'] as int;
    final carryTotal = carryMark!.totalCarryMark;

    // Total marks = Carry marks (50%) + Exam marks (50%)
    // We need: Total >= minTotalMark
    // So: carryTotal + examMark >= minTotalMark
    // examMark >= minTotalMark - carryTotal

    final requiredExamMark = minTotalMark - carryTotal;
    return requiredExamMark < 0 ? 0 : requiredExamMark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
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
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.blue,
                                  child: Icon(
                                    Icons.person,
                                    size: 35,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.student.fullName ??
                                          widget.student.username,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      widget.student.username,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your Carry Marks',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (carryMark == null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No marks available yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else ...[
                      Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildMarkRow('Test', carryMark!.testMark, 20),
                              const Divider(),
                              _buildMarkRow(
                                'Assignment',
                                carryMark!.assignmentMark,
                                10,
                              ),
                              const Divider(),
                              _buildMarkRow(
                                'Project',
                                carryMark!.projectMark,
                                20,
                              ),
                              const Divider(thickness: 2),
                              _buildMarkRow(
                                'Total Carry Mark',
                                carryMark!.totalCarryMark,
                                50,
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Grade Target Calculator',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select your target grade to see the required exam marks',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: selectedGrade,
                                decoration: const InputDecoration(
                                  labelText: 'Target Grade',
                                  border: OutlineInputBorder(),
                                ),
                                items: gradeRanges.keys.map((grade) {
                                  final range = gradeRanges[grade]!;
                                  return DropdownMenuItem(
                                    value: grade,
                                    child: Text(
                                      '$grade (${range['min']}-${range['max']})',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedGrade = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),
                              GradeCalculator(
                                carryMark: carryMark!,
                                targetGrade: selectedGrade,
                                gradeRange: gradeRanges[selectedGrade]!,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMarkRow(
    String label,
    double mark,
    double maxMark, {
    bool isTotal = false,
  }) {
    final percentage = (mark / maxMark * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,

            children: [
              Text(
                '${mark.toStringAsFixed(1)} / $maxMark',
                style: TextStyle(
                  fontSize: isTotal ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: isTotal ? Colors.blue : Colors.black,
                ),
              ),

              Text(
                '($percentage%)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
