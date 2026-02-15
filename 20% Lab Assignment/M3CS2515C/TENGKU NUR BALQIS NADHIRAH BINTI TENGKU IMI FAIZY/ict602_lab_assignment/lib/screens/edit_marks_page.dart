import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Page for editing student marks
class EditMarksPage extends StatefulWidget {
  final UserModel student;

  const EditMarksPage({super.key, required this.student});

  @override
  State<EditMarksPage> createState() => _EditMarksPageState();
}

class _EditMarksPageState extends State<EditMarksPage> {
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _testController;
  late TextEditingController _assignmentController;
  late TextEditingController _projectController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _testController = TextEditingController(
      text: widget.student.test.toString(),
    );
    _assignmentController = TextEditingController(
      text: widget.student.assignment.toString(),
    );
    _projectController = TextEditingController(
      text: widget.student.project.toString(),
    );
  }

  @override
  void dispose() {
    _testController.dispose();
    _assignmentController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  double get _totalMarks {
    double test = double.tryParse(_testController.text) ?? 0;
    double assignment = double.tryParse(_assignmentController.text) ?? 0;
    double project = double.tryParse(_projectController.text) ?? 0;
    return test + assignment + project;
  }

  Future<void> _saveMarks() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    double test = double.parse(_testController.text);
    double assignment = double.parse(_assignmentController.text);
    double project = double.parse(_projectController.text);

    bool success = await _databaseService.updateStudentMarks(
      widget.student.email,
      test,
      assignment,
      project,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ Marks saved successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true); // Return true to indicate success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save marks'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  String? _validateMark(String? value, double maxMark, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName mark';
    }
    double? mark = double.tryParse(value);
    if (mark == null) {
      return 'Please enter a valid number';
    }
    if (mark < 0 || mark > maxMark) {
      return 'Mark must be between 0 and ${maxMark.toInt()}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Marks'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Info Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Text(
                              widget.student.name.isNotEmpty
                                  ? widget.student.name[0].toUpperCase()
                                  : widget.student.email[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.student.name.isNotEmpty
                                      ? widget.student.name
                                      : 'Student',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.student.email,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Total Marks Preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryLight.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calculate, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Total Carry Mark: ',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${_totalMarks.toStringAsFixed(1)} / 50',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Marks Entry Section
              Text(
                'Enter Marks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Test Field
              _buildMarkField(
                controller: _testController,
                label: 'Test',
                maxMark: 20,
                icon: Icons.quiz_outlined,
                color: AppTheme.testColor,
              ),
              const SizedBox(height: 16),

              // Assignment Field
              _buildMarkField(
                controller: _assignmentController,
                label: 'Assignment',
                maxMark: 10,
                icon: Icons.assignment_outlined,
                color: AppTheme.assignmentColor,
              ),
              const SizedBox(height: 16),

              // Project Field
              _buildMarkField(
                controller: _projectController,
                label: 'Project',
                maxMark: 20,
                icon: Icons.folder_outlined,
                color: AppTheme.projectColor,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveMarks,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save, size: 24),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Marks',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkField({
    required TextEditingController controller,
    required String label,
    required double maxMark,
    required IconData icon,
    required Color color,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: '$label (Max: ${maxMark.toInt()}%)',
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.surface,
        suffixText: '/ ${maxMark.toInt()}',
        suffixStyle: TextStyle(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
      validator: (value) => _validateMark(value, maxMark, label),
      onChanged: (value) => setState(() {}), // Trigger rebuild for total
      style: const TextStyle(fontSize: 18),
    );
  }
}
