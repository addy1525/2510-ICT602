import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Target Score Page for grade calculation
/// Calculates required final exam mark based on target grade
class TargetScorePage extends StatefulWidget {
  final double currentCarryMark;

  const TargetScorePage({super.key, required this.currentCarryMark});

  @override
  State<TargetScorePage> createState() => _TargetScorePageState();
}

class _TargetScorePageState extends State<TargetScorePage> {
  String? _selectedGrade;
  double? _requiredFinalMark;
  String? _resultMessage;

  // Grade ranges (minimum marks required)
  final Map<String, Map<String, dynamic>> _gradeRanges = {
    'A+': {'min': 90, 'max': 100, 'color': const Color(0xFF1B5E20)},
    'A': {'min': 80, 'max': 89, 'color': const Color(0xFF2E7D32)},
    'A-': {'min': 75, 'max': 79, 'color': const Color(0xFF388E3C)},
    'B+': {'min': 70, 'max': 74, 'color': const Color(0xFF1976D2)},
    'B': {'min': 65, 'max': 69, 'color': const Color(0xFF1E88E5)},
    'B-': {'min': 60, 'max': 64, 'color': const Color(0xFF42A5F5)},
    'C+': {'min': 55, 'max': 59, 'color': const Color(0xFFF57C00)},
    'C': {'min': 50, 'max': 54, 'color': const Color(0xFFFF9800)},
  };

  void _calculateRequiredMark() {
    if (_selectedGrade == null) return;

    int targetMinMark = _gradeRanges[_selectedGrade]!['min'];
    double requiredFinal = targetMinMark - widget.currentCarryMark;

    setState(() {
      _requiredFinalMark = requiredFinal;

      if (requiredFinal <= 0) {
        _resultMessage =
            'Congratulations! You have already achieved enough carry marks for grade $_selectedGrade. You need at least 0 marks in the final exam.';
        _requiredFinalMark = 0;
      } else if (requiredFinal > 50) {
        _resultMessage =
            'Unfortunately, achieving grade $_selectedGrade is not possible with your current carry marks. The maximum final exam mark is 50, but you would need $requiredFinal marks.';
      } else {
        _resultMessage =
            'To achieve grade $_selectedGrade (${_gradeRanges[_selectedGrade]!['min']}-${_gradeRanges[_selectedGrade]!['max']}), you need at least ${requiredFinal.toStringAsFixed(1)} marks out of 50 in the final examination.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Score Calculator'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryLight.withOpacity(0.1), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Carry Mark Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your Current Carry Mark',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.currentCarryMark.toStringAsFixed(1)} / 50',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Final Exam: 50% remaining',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Grade Selection
              Text(
                'Select Your Target Grade',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Grade Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Choose a grade...'),
                    value: _selectedGrade,
                    items: _gradeRanges.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: entry.value['color'],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${entry.key} (${entry.value['min']}-${entry.value['max']})',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGrade = value;
                        _requiredFinalMark = null;
                        _resultMessage = null;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Calculate Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _selectedGrade == null
                      ? null
                      : _calculateRequiredMark,
                  icon: const Icon(Icons.calculate, size: 28),
                  label: const Text(
                    'Calculate Required Mark',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Result Card
              if (_requiredFinalMark != null && _resultMessage != null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          _requiredFinalMark! > 50
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle,
                          size: 64,
                          color: _requiredFinalMark! > 50
                              ? AppTheme.warning
                              : AppTheme.success,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _requiredFinalMark! > 50
                              ? 'Not Achievable'
                              : 'Required Final Exam Mark',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _requiredFinalMark! > 50
                                ? AppTheme.warning
                                : AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_requiredFinalMark! <= 50)
                          Text(
                            '${_requiredFinalMark!.toStringAsFixed(1)} / 50',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          _resultMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Grade Reference Table
              Text(
                'Grade Reference',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: _gradeRanges.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 32,
                              decoration: BoxDecoration(
                                color: entry.value['color'],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${entry.value['min']} - ${entry.value['max']} marks',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
