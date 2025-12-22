class CarryMark {
  final int? id;
  final String studentUsername;
  final double testMark;
  final double assignmentMark;
  final double projectMark;
  final String studentName;

  CarryMark({
    this.id,
    required this.studentUsername,
    required this.testMark,
    required this.assignmentMark,
    required this.projectMark,
    required this.studentName,
  });

  double get totalCarryMark => testMark + assignmentMark + projectMark;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentUsername': studentUsername,
      'testMark': testMark,
      'assignmentMark': assignmentMark,
      'projectMark': projectMark,
      'studentName': studentName,
    };
  }

  factory CarryMark.fromMap(Map<String, dynamic> map) {
    return CarryMark(
      id: map['id'],
      studentUsername: map['studentUsername'],
      testMark: map['testMark'],
      assignmentMark: map['assignmentMark'],
      projectMark: map['projectMark'],
      studentName: map['studentName'],
    );
  }
}
