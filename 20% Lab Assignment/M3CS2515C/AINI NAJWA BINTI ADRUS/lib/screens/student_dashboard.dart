import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/marks_service.dart';
import '../models/marks.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => StudentDashboardState();
}

class StudentDashboardState extends State<StudentDashboard> {
  Marks? _marks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final marksService = MarksService();

    if (authProvider.currentUser != null) {
      final marks = await marksService.getMarksByStudentId(
        authProvider.currentUser!.id!,
      );
      if (mounted) {
        setState(() {
          _marks = marks;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Student Dashboard - ICT602'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 24),
            onPressed: () {
              authProvider.logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE3F2FD),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF2196F3),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome, Student!',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                authProvider.currentUser?.fullName ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${authProvider.currentUser?.username ?? ''}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Current Carry Marks Section
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.assignment,
                          color: Color(0xFF2196F3),
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Current Carry Marks',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildMarksCard(),

                  const SizedBox(height: 30),

                  // Grade Target Calculator Section
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate,
                          color: Color(0xFF2196F3),
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Grade Target Calculator',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildGradeCalculator(),

                  const SizedBox(height: 30),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FD),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFBBDEFB)),
                    ),
                    child: const Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF1976D2),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Important Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          '• Final exam contributes 50% to your total grade\n'
                          '• Carry marks contribute 50% (Test 20%, Assignment 10%, Project 20%)\n'
                          '• Minimum passing grade is C (50%)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF555555),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMarksCard() {
    if (_marks == null) return const SizedBox();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildMarkRow('Test (20%)', _marks!.testMark, Icons.quiz),
            const Divider(height: 24),
            _buildMarkRow(
                'Assignment (10%)', _marks!.assignmentMark, Icons.assignment),
            const Divider(height: 24),
            _buildMarkRow('Project (20%)', _marks!.projectMark, Icons.work),
            const Divider(height: 24, thickness: 2),
            _buildMarkRow('Total Carry Mark (50%)', _marks!.totalCarryMark,
                Icons.summarize),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkRow(String label, double mark, IconData icon) {
    final isTotal = label.contains('Total');
    final maxMark = isTotal ? 50 : 100;
    final color = _getColorForMark(mark);

    // Predefined RGB values for each color to avoid deprecated methods
    final Map<Color, List<int>> colorRGB = {
      const Color(0xFF2E7D32): [46, 125, 50], // Green
      const Color(0xFF1976D2): [25, 118, 210], // Blue
      const Color(0xFFF57C00): [245, 124, 0], // Orange
      const Color(0xFFD32F2F): [211, 47, 47], // Red
    };

    final rgb = colorRGB[color] ?? [33, 150, 243]; // Default to blue
    final red = rgb[0];
    final green = rgb[1];
    final blue = rgb[2];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F8FF),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2196F3),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF555555),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color.fromRGBO(red, green, blue, 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              border: Border.all(
                color: Color.fromRGBO(red, green, blue, 0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${mark.toStringAsFixed(2)}/$maxMark',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForMark(double mark) {
    if (mark >= 80) return const Color(0xFF2E7D32); // Green
    if (mark >= 70) return const Color(0xFF1976D2); // Blue
    if (mark >= 60) return const Color(0xFFF57C00); // Orange
    return const Color(0xFFD32F2F); // Red
  }

  Widget _buildGradeCalculator() {
    if (_marks == null) return const SizedBox();

    // Predefined grade data with RGB values
    final List<Map<String, dynamic>> grades = [
      {
        'grade': 'A+',
        'range': '90-100',
        'min': 90.0,
        'color': const Color(0xFF2E7D32),
        'rgb': [46, 125, 50]
      },
      {
        'grade': 'A',
        'range': '80-89',
        'min': 80.0,
        'color': const Color(0xFF43A047),
        'rgb': [67, 160, 71]
      },
      {
        'grade': 'A-',
        'range': '75-79',
        'min': 75.0,
        'color': const Color(0xFF66BB6A),
        'rgb': [102, 187, 106]
      },
      {
        'grade': 'B+',
        'range': '70-74',
        'min': 70.0,
        'color': const Color(0xFF1976D2),
        'rgb': [25, 118, 210]
      },
      {
        'grade': 'B',
        'range': '65-69',
        'min': 65.0,
        'color': const Color(0xFF2196F3),
        'rgb': [33, 150, 243]
      },
      {
        'grade': 'B-',
        'range': '60-64',
        'min': 60.0,
        'color': const Color(0xFF64B5F6),
        'rgb': [100, 181, 246]
      },
      {
        'grade': 'C+',
        'range': '55-59',
        'min': 55.0,
        'color': const Color(0xFFF57C00),
        'rgb': [245, 124, 0]
      },
      {
        'grade': 'C',
        'range': '50-54',
        'min': 50.0,
        'color': const Color(0xFFFB8C00),
        'rgb': [251, 140, 0]
      },
    ];

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Final Exam Score Needed for Target Grade',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Based on your current carry marks',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Grade Cards Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: grades.length,
              itemBuilder: (context, index) {
                final grade = grades[index];
                final minTotal = grade['min'] as double;
                final carryMark = _marks!.totalCarryMark;
                final examNeeded = ((minTotal - carryMark) / 0.5).clamp(0, 100);
                final gradeColor = grade['color'] as Color;
                final rgb = grade['rgb'] as List<int>;
                final red = rgb[0];
                final green = rgb[1];
                final blue = rgb[2];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    border: Border.all(
                      color: const Color(0xFFEEEEEE),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 6,
                        spreadRadius: 2,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Grade Label
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(red, green, blue, 0.1),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Text(
                            grade['grade'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: gradeColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Range
                        Text(
                          grade['range'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Exam Needed
                        Text(
                          examNeeded <= 100
                              ? examNeeded.toStringAsFixed(1)
                              : '>100',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: examNeeded <= 100 ? gradeColor : Colors.red,
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFFFF9800),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Note: You need to score the calculated marks in the final exam (worth 50%) to achieve each grade.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
