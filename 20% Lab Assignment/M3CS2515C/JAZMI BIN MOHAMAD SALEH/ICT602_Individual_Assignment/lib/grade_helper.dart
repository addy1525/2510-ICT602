// lib/grade_helper.dart

class Grade {
  final String grade;    // Contoh: "A", "A-", "B+"
  final int minTotal;    // Min markah keseluruhan (carry + final) untuk grade ni
  final int maxTotal;    // Max markah keseluruhan

  const Grade({
    required this.grade,
    required this.minTotal,
    required this.maxTotal,
  });
}

// Boleh ubah range ni ikut rubrik subjek kamu
const List<Grade> gradeList = [
  Grade(grade: 'A+', minTotal: 90, maxTotal: 100),
  Grade(grade: 'A',  minTotal: 80, maxTotal: 89),
  Grade(grade: 'A-', minTotal: 75, maxTotal: 79),
  Grade(grade: 'B+', minTotal: 70, maxTotal: 74),
  Grade(grade: 'B',  minTotal: 65, maxTotal: 69),
  Grade(grade: 'B-', minTotal: 60, maxTotal: 64),
  Grade(grade: 'C+',  minTotal: 55, maxTotal: 59),
  Grade(grade: 'C',  minTotal: 50, maxTotal: 54),
];

/// Kira berapa markah final exam (daripada 50) yang diperlukan
/// untuk capai sekurang-kurangnya `grade.minTotal` keseluruhan.
///
/// totalCarry: markah carry sekarang (0–50)
double requiredFinalText(double totalCarry, Grade grade) {
  // Total markah yang diperlukan untuk dapat grade ni
  final double requiredOverall = grade.minTotal.toDouble();

  // Markah final yang perlu ditambah kepada carry sekarang
  final double needed = requiredOverall - totalCarry;

  // Kalau carry mark dah cukup untuk grade tu, tak perlu markah final lagi
  if (needed <= 0) {
    return 0;
  }

  // Boleh jadi > 50; di UI kita akan label sebagai "Challenging"
  return needed;
}
