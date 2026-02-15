import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_screen.dart';

class LecturerHome extends StatefulWidget {
  const LecturerHome({super.key});

  @override
  State<LecturerHome> createState() => _LecturerHomeState();
}

class _LecturerHomeState extends State<LecturerHome> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _testController = TextEditingController();
  final TextEditingController _assignmentController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();

  bool _saving = false;
  String? _message;
  bool _showSuccess = false;

  String? _validateMark(String? value, double max) {
    if (value == null || value.isEmpty) return 'Required field';
    final v = double.tryParse(value);
    if (v == null) return 'Enter a valid number';
    if (v < 0 || v > max) return 'Marks must be between 0 - $max';
    return null;
  }

  Future<void> _saveCarryMark() async {
    if (!_formKey.currentState!.validate()) return;

    // Close keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
      _message = null;
      _showSuccess = false;
    });

    try {
      final studentId = _studentIdController.text.trim();
      final test = double.parse(_testController.text);
      final assignment = double.parse(_assignmentController.text);
      final project = double.parse(_projectController.text);

      final totalCarry = test + assignment + project; // max 50

      await FirebaseFirestore.instance
          .collection('carryMarks')
          .doc(studentId)
          .set({
        'studentId': studentId,
        'subject': 'ICT602',
        'test': test,
        'assignment': assignment,
        'project': project,
        'totalCarry': totalCarry,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _message = 'Carry marks saved successfully! Total: $totalCarry / 50';
        _showSuccess = true;
      });

      // Auto-clear form after successful save
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showSuccess = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _message = 'Error saving data: $e';
        _showSuccess = false;
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _studentIdController.clear();
    _testController.clear();
    _assignmentController.clear();
    _projectController.clear();
    setState(() {
      _message = null;
      _showSuccess = false;
    });
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: theme.colorScheme.primary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.dividerColor,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.dividerColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
        ],
        validator: validator,
        onChanged: (_) {
          if (_message != null) {
            setState(() {
              _message = null;
            });
          }
        },
      ),
    );
  }

  Widget _buildMaxMarksIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue[100]!,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Maximum Marks',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMaxMarkItem('Test', '20', Colors.blue),
              _buildMaxMarkItem('Assignment', '10', Colors.green),
              _buildMaxMarkItem('Project', '20', Colors.purple),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMaxMarkItem('Total Carry Mark', '50', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaxMarkItem(String title, String max, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                max,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final purpleColor = Colors.purple;
    final blueColor = Colors.blue;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: 20,
                bottom: 20,
                left: screenWidth > 600 ? 32 : 16,
                right: screenWidth > 600 ? 32 : 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                    purpleColor[900]!,
                    purpleColor[700]!,
                    purpleColor[600]!,
                  ]
                      : [
                    purpleColor[700]!,
                    purpleColor[600]!,
                    purpleColor[500]!,
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lecturer Portal',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'ICT602 Marks',
                                style: TextStyle(
                                  fontSize: screenWidth > 600 ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(screenWidth > 600 ? 24 : 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 600,
                  ),
                  child: Column(
                    children: [
                      // Info Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: purpleColor,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Enter student carry marks for ICT602. System calculates total automatically.',
                                  style: TextStyle(
                                    fontSize: screenWidth > 600 ? 14 : 13,
                                    height: 1.5,
                                    color: isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Max Marks Indicator
                      _buildMaxMarksIndicator(),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Student ID
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: blueColor[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_search,
                                    color: blueColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Student Information',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: blueColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            _buildInputField(
                              controller: _studentIdController,
                              label: 'Student ID (Matrix Number)',
                              hint: 'Enter student ID',
                              icon: Icons.badge,
                              validator: (v) =>
                              v == null || v.isEmpty ? 'Required field' : null,
                            ),

                            // Marks Section
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.assessment,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Enter Marks',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            _buildInputField(
                              controller: _testController,
                              label: 'Test Marks (0 - 20)',
                              hint: 'Enter Test Marks',
                              icon: Icons.quiz,
                              validator: (v) => _validateMark(v, 20),
                            ),

                            _buildInputField(
                              controller: _assignmentController,
                              label: 'Assignment Marks (0 - 10)',
                              hint: 'Enter assignment marks',
                              icon: Icons.assignment,
                              validator: (v) => _validateMark(v, 10),
                            ),

                            _buildInputField(
                              controller: _projectController,
                              label: 'Project Marks (0 - 20)',
                              hint: 'Enter project marks',
                              icon: Icons.work,
                              validator: (v) => _validateMark(v, 20),
                            ),

                            const SizedBox(height: 20),

                            // Message Display
                            if (_message != null)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: _showSuccess
                                      ? Colors.green[50]
                                      : Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _showSuccess
                                        ? Colors.green[200]!
                                        : Colors.red[200]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _showSuccess
                                          ? Icons.check_circle
                                          : Icons.error_outline,
                                      color: _showSuccess
                                          ? Colors.green
                                          : Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _message!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _showSuccess
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Buttons - Stack vertically on small screens
                            if (screenWidth > 600)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _clearForm,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(
                                          color: theme.dividerColor,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.clear, size: 20),
                                          SizedBox(width: 8),
                                          Text('CLEAR FORM'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _saving ? null : _saveCarryMark,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: purpleColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        elevation: 4,
                                      ),
                                      child: _saving
                                          ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      )
                                          : const Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.save, size: 20),
                                          SizedBox(width: 8),
                                          Text('SAVE MARKS'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _saving ? null : _saveCarryMark,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: purpleColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        elevation: 4,
                                      ),
                                      child: _saving
                                          ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      )
                                          : const Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.save, size: 20),
                                          SizedBox(width: 8),
                                          Text('SAVE MARKS'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: _clearForm,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(
                                          color: theme.dividerColor,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.clear, size: 20),
                                          SizedBox(width: 8),
                                          Text('CLEAR FORM'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 20),

                            // Total Preview
                            if (_testController.text.isNotEmpty &&
                                _assignmentController.text.isNotEmpty &&
                                _projectController.text.isNotEmpty)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange[200]!,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Preview Total',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (screenWidth > 600)
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Test: ${_testController.text}',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                          ),
                                          Text(
                                            'Assignment: ${_assignmentController.text}',
                                            style: const TextStyle(
                                              color: Colors.green,
                                            ),
                                          ),
                                          Text(
                                            'Project: ${_projectController.text}',
                                            style: const TextStyle(
                                              color: Colors.purple,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Column(
                                        children: [
                                          Text(
                                            'Test: ${_testController.text}',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Assignment: ${_assignmentController.text}',
                                            style: const TextStyle(
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Project: ${_projectController.text}',
                                            style: const TextStyle(
                                              color: Colors.purple,
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 8),
                                    Divider(
                                      color: Colors.orange[200],
                                      height: 1,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Total Carry: ${_calculateTotal()} / 50',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateTotal() {
    try {
      final test = double.tryParse(_testController.text) ?? 0;
      final assignment = double.tryParse(_assignmentController.text) ?? 0;
      final project = double.tryParse(_projectController.text) ?? 0;
      return (test + assignment + project).toStringAsFixed(1);
    } catch (e) {
      return '0.0';
    }
  }
}