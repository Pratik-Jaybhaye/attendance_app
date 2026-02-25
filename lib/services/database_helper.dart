import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/attendance_record.dart';
import '../models/user.dart';

/// DatabaseHelper class for managing local SQLite database
/// Handles all CRUD operations for attendance records and user data
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  static Database? _database;

  // Database name and version
  static const String _databaseName = 'attendance_app.db';
  static const int _databaseVersion =
      3; // Bumped to trigger onUpgrade for table creation

  // Table names
  static const String tableAttendance = 'attendance_records';
  static const String tableStudentAttendance = 'student_attendance';
  static const String tableUsers = 'users';

  // Column names for attendance_records table
  static const String columnId = 'id';
  static const String columnClassId = 'class_id';
  static const String columnPeriodId = 'period_id';
  static const String columnDateTime = 'date_time';
  static const String columnRemarks = 'remarks';
  static const String columnIsSubmitted = 'is_submitted';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  // Column names for student_attendance table
  static const String columnStudentId = 'student_id';
  static const String columnAttendanceId = 'attendance_id';
  static const String columnIsPresent = 'is_present';

  // Column names for users table
  static const String columnUsername = 'username';
  static const String columnEmail = 'email';
  static const String columnPassword = 'password';
  static const String columnFullName = 'full_name';
  static const String columnProfileImagePath = 'profile_image_path';
  static const String columnRole = 'role';
  static const String columnLastLogin = 'last_login';
  static const String columnIsActive = 'is_active';

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE $tableUsers (
        $columnId TEXT PRIMARY KEY,
        $columnUsername TEXT NOT NULL UNIQUE,
        $columnEmail TEXT NOT NULL UNIQUE,
        $columnPassword TEXT NOT NULL,
        $columnFullName TEXT,
        $columnProfileImagePath TEXT,
        $columnRole TEXT,
        $columnCreatedAt TEXT NOT NULL,
        $columnLastLogin TEXT,
        $columnIsActive INTEGER DEFAULT 1
      )
    ''');

    // Create attendance records table
    await db.execute('''
      CREATE TABLE $tableAttendance (
        $columnId TEXT PRIMARY KEY,
        $columnClassId TEXT NOT NULL,
        $columnPeriodId TEXT NOT NULL,
        $columnDateTime TEXT NOT NULL,
        $columnRemarks TEXT,
        $columnIsSubmitted INTEGER DEFAULT 0,
        $columnCreatedAt TEXT NOT NULL,
        $columnUpdatedAt TEXT NOT NULL
      )
    ''');

    // Create student attendance table
    await db.execute('''
      CREATE TABLE $tableStudentAttendance (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnAttendanceId TEXT NOT NULL,
        $columnStudentId TEXT NOT NULL,
        $columnIsPresent INTEGER NOT NULL,
        FOREIGN KEY ($columnAttendanceId) REFERENCES $tableAttendance($columnId) ON DELETE CASCADE,
        UNIQUE($columnAttendanceId, $columnStudentId)
      )
    ''');

    print('Database tables created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future database schema changes here
    if (oldVersion < newVersion) {
      // Try to create users table if it doesn't exist
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableUsers (
            $columnId TEXT PRIMARY KEY,
            $columnUsername TEXT NOT NULL UNIQUE,
            $columnEmail TEXT NOT NULL UNIQUE,
            $columnPassword TEXT NOT NULL,
            $columnFullName TEXT,
            $columnProfileImagePath TEXT,
            $columnRole TEXT,
            $columnCreatedAt TEXT NOT NULL,
            $columnLastLogin TEXT,
            $columnIsActive INTEGER DEFAULT 1
          )
        ''');
        print('Users table created/verified during upgrade');
      } catch (e) {
        print('Users table already exists or error creating: $e');
      }

      // Try to create attendance records table if it doesn't exist
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableAttendance (
            $columnId TEXT PRIMARY KEY,
            $columnClassId TEXT NOT NULL,
            $columnPeriodId TEXT NOT NULL,
            $columnDateTime TEXT NOT NULL,
            $columnRemarks TEXT,
            $columnIsSubmitted INTEGER DEFAULT 0,
            $columnCreatedAt TEXT NOT NULL,
            $columnUpdatedAt TEXT NOT NULL
          )
        ''');
        print('Attendance table created/verified during upgrade');
      } catch (e) {
        print('Attendance table already exists or error creating: $e');
      }

      // Try to create student attendance table if it doesn't exist
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableStudentAttendance (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnAttendanceId TEXT NOT NULL,
            $columnStudentId TEXT NOT NULL,
            $columnIsPresent INTEGER NOT NULL,
            FOREIGN KEY ($columnAttendanceId) REFERENCES $tableAttendance($columnId) ON DELETE CASCADE,
            UNIQUE($columnAttendanceId, $columnStudentId)
          )
        ''');
        print('Student attendance table created/verified during upgrade');
      } catch (e) {
        print('Student attendance table already exists or error creating: $e');
      }
    }
  }

  // ==================== SAVE OPERATIONS ====================

  /// Save attendance record to local database
  /// Returns true if successful, false otherwise
  Future<bool> saveAttendanceRecord(AttendanceRecord record) async {
    try {
      final db = await database;

      // Insert attendance record
      await db.insert(tableAttendance, {
        columnId: record.id,
        columnClassId: record.classId,
        columnPeriodId: record.periodId,
        columnDateTime: record.dateTime.toIso8601String(),
        columnRemarks: record.remarks,
        columnIsSubmitted: record.isSubmitted ? 1 : 0,
        columnCreatedAt: DateTime.now().toIso8601String(),
        columnUpdatedAt: DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Insert student attendance records
      for (final entry in record.studentAttendance.entries) {
        await db.insert(tableStudentAttendance, {
          columnAttendanceId: record.id,
          columnStudentId: entry.key,
          columnIsPresent: entry.value ? 1 : 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      print('Attendance record saved successfully: ${record.id}');
      return true;
    } catch (e) {
      print('Error saving attendance record: $e');
      return false;
    }
  }

  /// Save multiple attendance records (batch save)
  Future<bool> saveBatchAttendanceRecords(
    List<AttendanceRecord> records,
  ) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (final record in records) {
        // Insert attendance record
        batch.insert(tableAttendance, {
          columnId: record.id,
          columnClassId: record.classId,
          columnPeriodId: record.periodId,
          columnDateTime: record.dateTime.toIso8601String(),
          columnRemarks: record.remarks,
          columnIsSubmitted: record.isSubmitted ? 1 : 0,
          columnCreatedAt: DateTime.now().toIso8601String(),
          columnUpdatedAt: DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        // Insert student attendance records
        for (final entry in record.studentAttendance.entries) {
          batch.insert(tableStudentAttendance, {
            columnAttendanceId: record.id,
            columnStudentId: entry.key,
            columnIsPresent: entry.value ? 1 : 0,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      await batch.commit(noResult: false);
      print('Batch attendance records saved successfully: ${records.length}');
      return true;
    } catch (e) {
      print('Error saving batch attendance records: $e');
      return false;
    }
  }

  // ==================== RETRIEVE OPERATIONS ====================

  /// Get attendance record by ID
  Future<AttendanceRecord?> getAttendanceRecord(String recordId) async {
    try {
      final db = await database;

      final attendanceList = await db.query(
        tableAttendance,
        where: '$columnId = ?',
        whereArgs: [recordId],
      );

      if (attendanceList.isEmpty) {
        return null;
      }

      final attendanceData = attendanceList.first;

      // Fetch student attendance records
      final studentRecords = await db.query(
        tableStudentAttendance,
        where: '$columnAttendanceId = ?',
        whereArgs: [recordId],
      );

      final studentAttendance = <String, bool>{};
      for (final record in studentRecords) {
        studentAttendance[record[columnStudentId] as String] =
            (record[columnIsPresent] as int) == 1;
      }

      return AttendanceRecord(
        id: attendanceData[columnId] as String,
        classId: attendanceData[columnClassId] as String,
        periodId: attendanceData[columnPeriodId] as String,
        dateTime: DateTime.parse(attendanceData[columnDateTime] as String),
        studentAttendance: studentAttendance,
        remarks: attendanceData[columnRemarks] as String? ?? '',
        isSubmitted: (attendanceData[columnIsSubmitted] as int) == 1,
      );
    } catch (e) {
      print('Error retrieving attendance record: $e');
      return null;
    }
  }

  /// Get all attendance records
  Future<List<AttendanceRecord>> getAllAttendanceRecords() async {
    try {
      final db = await database;

      final attendanceList = await db.query(
        tableAttendance,
        orderBy: '$columnDateTime DESC',
      );

      final records = <AttendanceRecord>[];

      for (final attendanceData in attendanceList) {
        final recordId = attendanceData[columnId] as String;

        // Fetch student attendance records
        final studentRecords = await db.query(
          tableStudentAttendance,
          where: '$columnAttendanceId = ?',
          whereArgs: [recordId],
        );

        final studentAttendance = <String, bool>{};
        for (final record in studentRecords) {
          studentAttendance[record[columnStudentId] as String] =
              (record[columnIsPresent] as int) == 1;
        }

        records.add(
          AttendanceRecord(
            id: recordId,
            classId: attendanceData[columnClassId] as String,
            periodId: attendanceData[columnPeriodId] as String,
            dateTime: DateTime.parse(attendanceData[columnDateTime] as String),
            studentAttendance: studentAttendance,
            remarks: attendanceData[columnRemarks] as String? ?? '',
            isSubmitted: (attendanceData[columnIsSubmitted] as int) == 1,
          ),
        );
      }

      return records;
    } catch (e) {
      print('Error retrieving all attendance records: $e');
      return [];
    }
  }

  /// Get attendance records by class ID
  Future<List<AttendanceRecord>> getAttendanceByClassId(String classId) async {
    try {
      final db = await database;

      final attendanceList = await db.query(
        tableAttendance,
        where: '$columnClassId = ?',
        whereArgs: [classId],
        orderBy: '$columnDateTime DESC',
      );

      final records = <AttendanceRecord>[];

      for (final attendanceData in attendanceList) {
        final recordId = attendanceData[columnId] as String;

        // Fetch student attendance records
        final studentRecords = await db.query(
          tableStudentAttendance,
          where: '$columnAttendanceId = ?',
          whereArgs: [recordId],
        );

        final studentAttendance = <String, bool>{};
        for (final record in studentRecords) {
          studentAttendance[record[columnStudentId] as String] =
              (record[columnIsPresent] as int) == 1;
        }

        records.add(
          AttendanceRecord(
            id: recordId,
            classId: attendanceData[columnClassId] as String,
            periodId: attendanceData[columnPeriodId] as String,
            dateTime: DateTime.parse(attendanceData[columnDateTime] as String),
            studentAttendance: studentAttendance,
            remarks: attendanceData[columnRemarks] as String? ?? '',
            isSubmitted: (attendanceData[columnIsSubmitted] as int) == 1,
          ),
        );
      }

      return records;
    } catch (e) {
      print('Error retrieving attendance by class ID: $e');
      return [];
    }
  }

  /// Get attendance records by date range
  Future<List<AttendanceRecord>> getAttendanceByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await database;

      final attendanceList = await db.query(
        tableAttendance,
        where: '$columnDateTime BETWEEN ? AND ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: '$columnDateTime DESC',
      );

      final records = <AttendanceRecord>[];

      for (final attendanceData in attendanceList) {
        final recordId = attendanceData[columnId] as String;

        // Fetch student attendance records
        final studentRecords = await db.query(
          tableStudentAttendance,
          where: '$columnAttendanceId = ?',
          whereArgs: [recordId],
        );

        final studentAttendance = <String, bool>{};
        for (final record in studentRecords) {
          studentAttendance[record[columnStudentId] as String] =
              (record[columnIsPresent] as int) == 1;
        }

        records.add(
          AttendanceRecord(
            id: recordId,
            classId: attendanceData[columnClassId] as String,
            periodId: attendanceData[columnPeriodId] as String,
            dateTime: DateTime.parse(attendanceData[columnDateTime] as String),
            studentAttendance: studentAttendance,
            remarks: attendanceData[columnRemarks] as String? ?? '',
            isSubmitted: (attendanceData[columnIsSubmitted] as int) == 1,
          ),
        );
      }

      return records;
    } catch (e) {
      print('Error retrieving attendance by date range: $e');
      return [];
    }
  }

  /// Get unsubmitted attendance records (for sync with backend)
  Future<List<AttendanceRecord>> getUnsubmittedAttendanceRecords() async {
    try {
      final db = await database;

      final attendanceList = await db.query(
        tableAttendance,
        where: '$columnIsSubmitted = 0',
        orderBy: '$columnDateTime ASC',
      );

      final records = <AttendanceRecord>[];

      for (final attendanceData in attendanceList) {
        final recordId = attendanceData[columnId] as String;

        // Fetch student attendance records
        final studentRecords = await db.query(
          tableStudentAttendance,
          where: '$columnAttendanceId = ?',
          whereArgs: [recordId],
        );

        final studentAttendance = <String, bool>{};
        for (final record in studentRecords) {
          studentAttendance[record[columnStudentId] as String] =
              (record[columnIsPresent] as int) == 1;
        }

        records.add(
          AttendanceRecord(
            id: recordId,
            classId: attendanceData[columnClassId] as String,
            periodId: attendanceData[columnPeriodId] as String,
            dateTime: DateTime.parse(attendanceData[columnDateTime] as String),
            studentAttendance: studentAttendance,
            remarks: attendanceData[columnRemarks] as String? ?? '',
            isSubmitted: (attendanceData[columnIsSubmitted] as int) == 1,
          ),
        );
      }

      return records;
    } catch (e) {
      print('Error retrieving unsubmitted attendance records: $e');
      return [];
    }
  }

  // ==================== UPDATE OPERATIONS ====================

  /// Update attendance record
  Future<bool> updateAttendanceRecord(AttendanceRecord record) async {
    try {
      final db = await database;

      // Update main attendance record
      await db.update(
        tableAttendance,
        {
          columnRemarks: record.remarks,
          columnIsSubmitted: record.isSubmitted ? 1 : 0,
          columnUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '$columnId = ?',
        whereArgs: [record.id],
      );

      // Delete old student attendance records
      await db.delete(
        tableStudentAttendance,
        where: '$columnAttendanceId = ?',
        whereArgs: [record.id],
      );

      // Insert updated student attendance records
      for (final entry in record.studentAttendance.entries) {
        await db.insert(tableStudentAttendance, {
          columnAttendanceId: record.id,
          columnStudentId: entry.key,
          columnIsPresent: entry.value ? 1 : 0,
        });
      }

      print('Attendance record updated successfully: ${record.id}');
      return true;
    } catch (e) {
      print('Error updating attendance record: $e');
      return false;
    }
  }

  /// Mark attendance record as submitted
  Future<bool> markAsSubmitted(String recordId) async {
    try {
      final db = await database;

      await db.update(
        tableAttendance,
        {
          columnIsSubmitted: 1,
          columnUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '$columnId = ?',
        whereArgs: [recordId],
      );

      print('Attendance record marked as submitted: $recordId');
      return true;
    } catch (e) {
      print('Error marking attendance record as submitted: $e');
      return false;
    }
  }

  // ==================== DELETE OPERATIONS ====================

  /// Delete attendance record by ID
  Future<bool> deleteAttendanceRecord(String recordId) async {
    try {
      final db = await database;

      // Delete student attendance records first (due to foreign key)
      await db.delete(
        tableStudentAttendance,
        where: '$columnAttendanceId = ?',
        whereArgs: [recordId],
      );

      // Delete attendance record
      await db.delete(
        tableAttendance,
        where: '$columnId = ?',
        whereArgs: [recordId],
      );

      print('Attendance record deleted successfully: $recordId');
      return true;
    } catch (e) {
      print('Error deleting attendance record: $e');
      return false;
    }
  }

  /// Delete all attendance records (use with caution)
  Future<bool> deleteAllAttendanceRecords() async {
    try {
      final db = await database;

      await db.delete(tableStudentAttendance);
      await db.delete(tableAttendance);

      print('All attendance records deleted');
      return true;
    } catch (e) {
      print('Error deleting all attendance records: $e');
      return false;
    }
  }

  /// Delete attendance records older than specified date
  Future<bool> deleteOldAttendanceRecords(DateTime beforeDate) async {
    try {
      final db = await database;

      // Get records to delete
      final recordsToDelete = await db.query(
        tableAttendance,
        where: '$columnDateTime < ?',
        whereArgs: [beforeDate.toIso8601String()],
        columns: [columnId],
      );

      final recordIds = recordsToDelete
          .map((r) => r[columnId] as String)
          .toList();

      // Delete student attendance records
      for (final recordId in recordIds) {
        await db.delete(
          tableStudentAttendance,
          where: '$columnAttendanceId = ?',
          whereArgs: [recordId],
        );
      }

      // Delete attendance records
      await db.delete(
        tableAttendance,
        where: '$columnDateTime < ?',
        whereArgs: [beforeDate.toIso8601String()],
      );

      print(
        'Attendance records older than ${beforeDate.toIso8601String()} deleted: ${recordIds.length}',
      );
      return true;
    } catch (e) {
      print('Error deleting old attendance records: $e');
      return false;
    }
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Get total count of attendance records
  Future<int> getTotalAttendanceRecords() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableAttendance',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting total attendance records count: $e');
      return 0;
    }
  }

  /// Get database size in bytes
  Future<int> getDatabaseSize() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA page_count');
      final pageCount = Sqflite.firstIntValue(result) ?? 0;

      final pageSize = await db.rawQuery('PRAGMA page_size');
      final size = Sqflite.firstIntValue(pageSize) ?? 0;

      return pageCount * size;
    } catch (e) {
      print('Error getting database size: $e');
      return 0;
    }
  }

  /// Close database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // ==================== USER OPERATIONS ====================

  /// Save user to database (Create new user)
  Future<bool> saveUser(User user) async {
    try {
      final db = await database;
      await db.insert(tableUsers, {
        columnId: user.id,
        columnUsername: user.username,
        columnEmail: user.email,
        columnPassword: user.password,
        columnFullName: user.fullName,
        columnProfileImagePath: user.profileImagePath,
        columnRole: user.role,
        columnCreatedAt: user.createdAt.toIso8601String(),
        columnLastLogin: user.lastLogin?.toIso8601String(),
        columnIsActive: user.isActive ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      print('User saved successfully: ${user.username}');
      return true;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  /// Get user by username
  Future<User?> getUserByUsername(String username) async {
    try {
      final db = await database;
      final result = await db.query(
        tableUsers,
        where: '$columnUsername = ?',
        whereArgs: [username],
      );

      if (result.isEmpty) {
        return null;
      }

      return User.fromJson(result.first);
    } catch (e) {
      print('Error getting user by username: $e');
      return null;
    }
  }

  /// Get user by email
  Future<User?> getUserByEmail(String email) async {
    try {
      final db = await database;
      final result = await db.query(
        tableUsers,
        where: '$columnEmail = ?',
        whereArgs: [email],
      );

      if (result.isEmpty) {
        return null;
      }

      return User.fromJson(result.first);
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final db = await database;
      final result = await db.query(
        tableUsers,
        where: '$columnId = ?',
        whereArgs: [userId],
      );

      if (result.isEmpty) {
        return null;
      }

      return User.fromJson(result.first);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  /// Get all users
  Future<List<User>> getAllUsers() async {
    try {
      final db = await database;
      final result = await db.query(
        tableUsers,
        orderBy: '$columnCreatedAt DESC',
      );

      return result.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// Verify user credentials (login)
  /// Returns user if credentials match, null otherwise
  Future<User?> verifyCredentials(String username, String password) async {
    try {
      final user = await getUserByUsername(username);

      if (user == null) {
        print('User not found: $username');
        return null;
      }

      // Verify password
      if (user.password == password) {
        // Update last login
        await updateUserLastLogin(user.id);
        return user;
      } else {
        print('Invalid password for user: $username');
        return null;
      }
    } catch (e) {
      print('Error verifying credentials: $e');
      return null;
    }
  }

  /// Update user information
  Future<bool> updateUser(User user) async {
    try {
      final db = await database;

      await db.update(
        tableUsers,
        {
          columnUsername: user.username,
          columnEmail: user.email,
          columnPassword: user.password,
          columnFullName: user.fullName,
          columnProfileImagePath: user.profileImagePath,
          columnRole: user.role,
          columnIsActive: user.isActive ? 1 : 0,
          columnUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '$columnId = ?',
        whereArgs: [user.id],
      );

      print('User updated successfully: ${user.username}');
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  /// Update user password
  Future<bool> updateUserPassword(String userId, String newPassword) async {
    try {
      final db = await database;

      await db.update(
        tableUsers,
        {columnPassword: newPassword},
        where: '$columnId = ?',
        whereArgs: [userId],
      );

      print('Password updated successfully for user: $userId');
      return true;
    } catch (e) {
      print('Error updating password: $e');
      return false;
    }
  }

  /// Update user last login time
  Future<bool> updateUserLastLogin(String userId) async {
    try {
      final db = await database;

      await db.update(
        tableUsers,
        {columnLastLogin: DateTime.now().toIso8601String()},
        where: '$columnId = ?',
        whereArgs: [userId],
      );

      return true;
    } catch (e) {
      print('Error updating last login: $e');
      return false;
    }
  }

  /// Check if username exists
  Future<bool> usernameExists(String username) async {
    try {
      final db = await database;
      final result = await db.query(
        tableUsers,
        where: '$columnUsername = ?',
        whereArgs: [username],
      );

      return result.isNotEmpty;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final db = await database;
      final result = await db.query(
        tableUsers,
        where: '$columnEmail = ?',
        whereArgs: [email],
      );

      return result.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  /// Delete user by ID
  Future<bool> deleteUser(String userId) async {
    try {
      final db = await database;

      await db.delete(tableUsers, where: '$columnId = ?', whereArgs: [userId]);

      print('User deleted successfully: $userId');
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  /// Delete all users
  Future<bool> deleteAllUsers() async {
    try {
      final db = await database;

      await db.delete(tableUsers);

      print('All users deleted');
      return true;
    } catch (e) {
      print('Error deleting all users: $e');
      return false;
    }
  }

  /// Get total user count
  Future<int> getTotalUserCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableUsers',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting user count: $e');
      return 0;
    }
  }
}
