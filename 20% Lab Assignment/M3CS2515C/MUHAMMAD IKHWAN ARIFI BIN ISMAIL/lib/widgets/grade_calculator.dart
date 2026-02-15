import 'package:flutter/material.dart';
import '../models/carry_mark.dart';

class GradeCalculator extends StatelessWidget {
  final CarryMark carryMark;
  final String targetGrade;
  final Map<String, dynamic> gradeRange;

  const GradeCalculator({
    Key? key,
    required this.carryMark,
    required this.targetGrade,
    required this.gradeRange,
  }) : super(key: key);

  Map<String, dynamic> calculateExamRequirement() {
    final carryTotal = carryMark.totalCarryMark;
    final minTotalMark = gradeRange['min'] as int;
    final maxTotalMark = gradeRange['max'] as int;

    // To get minimum grade: carryTotal + examMark = minTotalMark
    final minExamRequired = minTotalMark - carryTotal;

    // To get maximum grade: carryTotal + examMark = maxTotalMark
    final maxExamRequired = maxTotalMark - carryTotal;

    // Check if it's achievable (exam is out of 50)
    final isAchievable = minExamRequired <= 50;
    final guaranteedWithMaxExam = carryTotal + 50;

    return {
      'minExamRequired': minExamRequired < 0 ? 0 : minExamRequired,
      'maxExamRequired': maxExamRequired < 0 ? 0 : maxExamRequired,
      'isAchievable': isAchievable,
      'guaranteedGrade': guaranteedWithMaxExam,
      'carryTotal': carryTotal,
    };
  }

  @override
  Widget build(BuildContext context) {
    final result = calculateExamRequirement();
    final minExam = result['minExamRequired'] as double;
    final maxExam = result['maxExamRequired'] as double;
    final isAchievable = result['isAchievable'] as bool;
    final guaranteedTotal = result['guaranteedGrade'] as double;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAchievable ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAchievable ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAchievable ? Icons.check_circle : Icons.info,
                color: isAchievable ? Colors.green : Colors.orange,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Target: $targetGrade (${gradeRange['min']}-${gradeRange['max']} marks)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Your Carry Marks:',
                  '${carryMark.totalCarryMark.toStringAsFixed(1)} / 50',
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                if (isAchievable) ...[
                  _buildInfoRow(
                    'Minimum Exam Mark:',
                    '${minExam.toStringAsFixed(1)} / 50',
                    highlight: true,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'For Top of $targetGrade:',
                    '${maxExam.toStringAsFixed(1)} / 50',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.celebration,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            minExam <= 0
                                ? 'You already achieved $targetGrade!'
                                : 'This grade is achievable! Good luck!',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'This grade requires more than 50 marks in exam',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'With perfect exam score (50/50):',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Your total: ${guaranteedTotal.toStringAsFixed(1)} marks',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Note: Final exam is worth 50 marks',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 18 : 16,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            color: highlight ? Colors.blue : Colors.black,
          ),
        ),
      ],
    );
  }
}
