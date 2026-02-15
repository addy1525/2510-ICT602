class Marks {
  final int? id;
  final int studentId;
  double testMark;
  double assignmentMark;
  double projectMark;
  double finalExamMark;

  Marks({
    this.id,
    required this.studentId,
    required this.testMark,
    required this.assignmentMark,
    required this.projectMark,
    required this.finalExamMark,
  });

  double get totalCarryMark {
    return (testMark * 0.2) + (assignmentMark * 0.1) + (projectMark * 0.2);
  }

  double get totalFinalMark {
    return totalCarryMark + (finalExamMark * 0.5);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'test_mark': testMark,
      'assignment_mark': assignmentMark,
      'project_mark': projectMark,
      'final_exam_mark': finalExamMark,
    };
  }

  factory Marks.fromMap(Map<String, dynamic> map) {
    return Marks(
      id: map['id'],
      studentId: map['student_id'],
      testMark: map['test_mark'],
      assignmentMark: map['assignment_mark'],
      projectMark: map['project_mark'],
      finalExamMark: map['final_exam_mark'],
    );
  }
}
