//import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/marks.dart';

class MarksService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<Marks?> getMarksByStudentId(int studentId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'student_marks',
      where: 'student_id = ?',
      whereArgs: [studentId],
    );

    if (maps.isNotEmpty) {
      return Marks.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateMarks(Marks marks) async {
    final db = await _databaseHelper.database;
    await db.update(
      'student_marks',
      marks.toMap(),
      where: 'student_id = ?',
      whereArgs: [marks.studentId],
    );
  }

  Future<List<Marks>> getAllMarks() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('student_marks');

    return List.generate(maps.length, (i) {
      return Marks.fromMap(maps[i]);
    });
  }
}
