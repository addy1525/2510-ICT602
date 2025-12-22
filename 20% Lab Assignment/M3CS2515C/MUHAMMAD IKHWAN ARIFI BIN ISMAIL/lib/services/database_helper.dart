// DatabaseHelper.dart
// This class manages SQLite database operations for the ICT602 application.
// It handles user authentication and carry mark management with CRUD operations.

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/carry_mark.dart';

class DatabaseHelper {
  // Ensures only one instance exists throughout the app lifecycle.
  static final DatabaseHelper instance = DatabaseHelper._init();

  // Private database instance variable.
  // Null until database is initialized for the first time.
  static Database? _database;

  DatabaseHelper._init();

  // Database getter with lazy initialization.
  // Returns existing database if already initialized, otherwise initializes it.
  // Ensures database is only opened once.
  Future<Database> get database async {
    if (_database != null)
      return _database!; // Return cached instance if exists
    _database = await _initDB('ict602.db'); // Initialize database if first call
    return _database!;
  }

  // Initializes the SQLite database at the specified file path.
  // [filePath]: Name of the database file to create/open.
  // Returns a Future<Database> instance.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Creates database schema and seeds initial data.
  // Called only once when database is first created.
  // [db]: Database instance
  // [version]: Database version number
  Future<void> _createDB(Database db, int version) async {
    // Create users table with columns for user management
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        fullName TEXT
      )
    ''');

    // Create carry_marks table for storing student assessment marks
    await db.execute('''
      CREATE TABLE carry_marks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentUsername TEXT NOT NULL,
        testMark REAL NOT NULL,
        assignmentMark REAL NOT NULL,
        projectMark REAL NOT NULL,
        studentName TEXT NOT NULL,
        FOREIGN KEY (studentUsername) REFERENCES users (username)
      )
    ''');

    // Seed database with default user accounts
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
      'fullName': 'Administrator',
    });

    await db.insert('users', {
      'username': 'lecturer1',
      'password': 'lect123',
      'role': 'lecturer',
      'fullName': 'Dr. Ahmad',
    });

    await db.insert('users', {
      'username': 'student1',
      'password': 'stud123',
      'role': 'student',
      'fullName': 'Ali bin Abu',
    });

    await db.insert('users', {
      'username': 'student2',
      'password': 'stud123',
      'role': 'student',
      'fullName': 'Siti binti Hassan',
    });
  }

  // ================================= - USER OPERATIONS - =================================

  // Authenticates a user by username and password.
  Future<User?> loginUser(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Retrieves all users with 'student' role from the database.
  Future<List<User>> getAllStudents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['student'],
    );

    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  // ================================= - CARRY MARK OPERATIONS - =================================

  // Inserts or updates carry marks for a student.
  Future<int> insertCarryMark(CarryMark mark) async {
    final db = await database;

    // Check if mark already exists for this student
    final existing = await db.query(
      'carry_marks',
      where: 'studentUsername = ?',
      whereArgs: [mark.studentUsername],
    );

    if (existing.isNotEmpty) {
      // Update existing record - exclude id from update
      final updateMap = {
        'studentUsername': mark.studentUsername,
        'testMark': mark.testMark,
        'assignmentMark': mark.assignmentMark,
        'projectMark': mark.projectMark,
        'studentName': mark.studentName,
      };
      return await db.update(
        'carry_marks',
        updateMap,
        where: 'studentUsername = ?',
        whereArgs: [mark.studentUsername],
      );
    } else {
      // Insert new record
      return await db.insert('carry_marks', mark.toMap());
    }
  }

  // Retrieves carry marks for a specific student by username.
  Future<CarryMark?> getCarryMark(String studentUsername) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'carry_marks',
      where: 'studentUsername = ?',
      whereArgs: [studentUsername],
    );

    if (maps.isNotEmpty) {
      return CarryMark.fromMap(maps.first);
    }
    return null;
  }

  // Retrieves all carry marks from the database.
  Future<List<CarryMark>> getAllCarryMarks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('carry_marks');
    return List.generate(maps.length, (i) => CarryMark.fromMap(maps[i]));
  }

  // Closes the database connection.
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
