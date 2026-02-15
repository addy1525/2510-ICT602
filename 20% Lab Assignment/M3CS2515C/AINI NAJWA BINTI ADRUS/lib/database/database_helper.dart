import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ict602.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        full_name TEXT,
        email TEXT
      )
    ''');

    // Student marks table
    await db.execute('''
      CREATE TABLE student_marks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER,
        test_mark REAL DEFAULT 0,
        assignment_mark REAL DEFAULT 0,
        project_mark REAL DEFAULT 0,
        final_exam_mark REAL DEFAULT 0,
        FOREIGN KEY (student_id) REFERENCES users(id)
      )
    ''');

    // Insert sample data
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    // Insert admin
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
      'full_name': 'System Administrator',
      'email': 'admin@university.edu',
    });

    // Insert lecturer
    await db.insert('users', {
      'username': 'lecturer',
      'password': 'lecturer123',
      'role': 'lecturer',
      'full_name': 'Dr. Ahmad Zaki',
      'email': 'zaki@university.edu',
    });

    // Insert students
    List<Map<String, dynamic>> students = [
      {
        'username': 'student1',
        'password': 'student123',
        'role': 'student',
        'full_name': 'Ali bin Abu',
        'email': 'ali@student.university.edu',
      },
      {
        'username': 'student2',
        'password': 'student123',
        'role': 'student',
        'full_name': 'Siti Nurhaliza',
        'email': 'siti@student.university.edu',
      },
    ];

    for (var student in students) {
      int studentId = await db.insert('users', student);

      // Insert default marks for student
      await db.insert('student_marks', {
        'student_id': studentId,
        'test_mark': 0,
        'assignment_mark': 0,
        'project_mark': 0,
        'final_exam_mark': 0,
      });
    }
  }
}
