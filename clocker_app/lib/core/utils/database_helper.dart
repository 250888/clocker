import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../models/spacetime.dart';
import '../../models/task.dart';
import '../../models/focus_session.dart';
import '../../models/daily_record.dart';
import '../../models/achievement.dart';
import '../../models/app_settings.dart';
import 'database_interface.dart';

DatabaseHelperInterface createDatabaseHelper() => DatabaseHelper();

class DatabaseHelper implements DatabaseHelperInterface {
  static const _databaseName = 'clocker.db';
  static const _databaseVersion = 1;

  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    return openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE spacetimes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        deadline TEXT NOT NULL,
        v0 REAL NOT NULL,
        c REAL NOT NULL,
        flowMode INTEGER NOT NULL,
        advanceDays INTEGER NOT NULL,
        isActive INTEGER NOT NULL,
        appDeadline TEXT,
        totalFocusHours REAL NOT NULL,
        totalTaskValue REAL NOT NULL,
        totalScreenPenalty REAL NOT NULL,
        timeFreezesUsed INTEGER NOT NULL,
        timeRewindsUsed INTEGER NOT NULL,
        lastFreezeTime TEXT,
        emoji TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        spacetimeId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        vValueWeight REAL NOT NULL,
        status INTEGER NOT NULL,
        priority INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        dueDate TEXT,
        subtasks TEXT,
        completedSubtasks TEXT,
        verificationNote TEXT,
        FOREIGN KEY (spacetimeId) REFERENCES spacetimes (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE focus_sessions (
        id TEXT PRIMARY KEY,
        spacetimeId TEXT NOT NULL,
        mode INTEGER NOT NULL,
        status INTEGER NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        targetDurationMinutes INTEGER NOT NULL,
        actualDurationMinutes INTEGER NOT NULL,
        vValueEarned REAL NOT NULL,
        wasDistractionFree INTEGER NOT NULL,
        distractionCount INTEGER NOT NULL,
        wasFlowState INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY (spacetimeId) REFERENCES spacetimes (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_records (
        id TEXT PRIMARY KEY,
        spacetimeId TEXT NOT NULL,
        date TEXT NOT NULL,
        focusHours REAL NOT NULL,
        taskValue REAL NOT NULL,
        screenPenalty REAL NOT NULL,
        vValue REAL NOT NULL,
        flowRate REAL NOT NULL,
        sessionsCompleted INTEGER NOT NULL,
        tasksCompleted INTEGER NOT NULL,
        timeEarned REAL NOT NULL,
        timeLost REAL NOT NULL,
        hadFlowState INTEGER NOT NULL,
        flowStateDurationMinutes INTEGER NOT NULL,
        FOREIGN KEY (spacetimeId) REFERENCES spacetimes (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        tier INTEGER NOT NULL,
        category INTEGER NOT NULL,
        icon TEXT NOT NULL,
        requiredValue REAL NOT NULL,
        isUnlocked INTEGER NOT NULL,
        unlockedAt TEXT,
        reward TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        defaultV0 REAL NOT NULL,
        defaultC REAL NOT NULL,
        defaultAdvanceDays INTEGER NOT NULL,
        defaultFlowMode INTEGER NOT NULL,
        enableNotifications INTEGER NOT NULL,
        enableSoundEffects INTEGER NOT NULL,
        enableWhiteNoise INTEGER NOT NULL,
        enableScreenMonitoring INTEGER NOT NULL,
        enableCameraMonitoring INTEGER NOT NULL,
        enableMicrophoneMonitoring INTEGER NOT NULL,
        enableMotionMonitoring INTEGER NOT NULL,
        screenPenaltyWeight REAL NOT NULL,
        studyCreditWeight REAL NOT NULL,
        pomodoroDuration INTEGER NOT NULL,
        shortBreakDuration INTEGER NOT NULL,
        longBreakDuration INTEGER NOT NULL,
        pomodorosBeforeLongBreak INTEGER NOT NULL,
        privacyAccepted INTEGER NOT NULL,
        selectedTheme TEXT NOT NULL
      )
    ''');
  }

  // Spacetime CRUD
  @override
  Future<String> insertSpacetime(Spacetime st) async {
    final db = await database;
    await db.insert('spacetimes', st.toMap());
    return st.id;
  }

  @override
  Future<List<Spacetime>> getAllSpacetimes() async {
    final db = await database;
    final maps = await db.query('spacetimes', orderBy: 'createdAt DESC');
    return maps.map((m) => Spacetime.fromMap(m)).toList();
  }

  @override
  Future<Spacetime?> getSpacetime(String id) async {
    final db = await database;
    final maps = await db.query('spacetimes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Spacetime.fromMap(maps.first);
  }

  @override
  Future<void> updateSpacetime(Spacetime st) async {
    final db = await database;
    await db.update(
      'spacetimes',
      st.toMap(),
      where: 'id = ?',
      whereArgs: [st.id],
    );
  }

  @override
  Future<void> deleteSpacetime(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'spacetimeId = ?', whereArgs: [id]);
    await db.delete(
      'focus_sessions',
      where: 'spacetimeId = ?',
      whereArgs: [id],
    );
    await db.delete('daily_records', where: 'spacetimeId = ?', whereArgs: [id]);
    await db.delete('spacetimes', where: 'id = ?', whereArgs: [id]);
  }

  // Task CRUD
  @override
  Future<String> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
    return task.id;
  }

  @override
  Future<List<Task>> getTasksForSpacetime(String spacetimeId) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'spacetimeId = ?',
      whereArgs: [spacetimeId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  @override
  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // FocusSession CRUD
  @override
  Future<String> insertFocusSession(FocusSession session) async {
    final db = await database;
    await db.insert('focus_sessions', session.toMap());
    return session.id;
  }

  @override
  Future<List<FocusSession>> getFocusSessionsForSpacetime(
    String spacetimeId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'focus_sessions',
      where: 'spacetimeId = ?',
      whereArgs: [spacetimeId],
      orderBy: 'startTime DESC',
    );
    return maps.map((m) => FocusSession.fromMap(m)).toList();
  }

  @override
  Future<void> updateFocusSession(FocusSession session) async {
    final db = await database;
    await db.update(
      'focus_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  // DailyRecord CRUD
  @override
  Future<String> insertDailyRecord(DailyRecord record) async {
    final db = await database;
    await db.insert('daily_records', record.toMap());
    return record.id;
  }

  @override
  Future<List<DailyRecord>> getDailyRecordsForSpacetime(
    String spacetimeId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'daily_records',
      where: 'spacetimeId = ?',
      whereArgs: [spacetimeId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => DailyRecord.fromMap(m)).toList();
  }

  @override
  Future<DailyRecord?> getDailyRecord(String spacetimeId, DateTime date) async {
    final db = await database;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'daily_records',
      where: 'spacetimeId = ? AND date LIKE ?',
      whereArgs: [spacetimeId, '$dateStr%'],
    );
    if (maps.isEmpty) return null;
    return DailyRecord.fromMap(maps.first);
  }

  @override
  Future<void> updateDailyRecord(DailyRecord record) async {
    final db = await database;
    await db.update(
      'daily_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  // Achievement CRUD
  @override
  Future<void> initAchievements() async {
    final db = await database;
    final count = (await db.query('achievements')).length;
    if (count == 0) {
      for (final a in Achievement.defaultAchievements()) {
        await db.insert('achievements', a.toMap());
      }
    }
  }

  @override
  Future<List<Achievement>> getAllAchievements() async {
    final db = await database;
    final maps = await db.query(
      'achievements',
      orderBy: 'tier ASC, category ASC',
    );
    return maps.map((m) => Achievement.fromMap(m)).toList();
  }

  @override
  Future<void> updateAchievement(Achievement achievement) async {
    final db = await database;
    await db.update(
      'achievements',
      achievement.toMap(),
      where: 'id = ?',
      whereArgs: [achievement.id],
    );
  }

  // Settings
  @override
  Future<void> saveSettings(AppSettings settings) async {
    final db = await database;
    final count = (await db.query('app_settings')).length;
    if (count == 0) {
      await db.insert('app_settings', settings.toMap());
    } else {
      await db.update('app_settings', settings.toMap(), where: 'id = 1');
    }
  }

  @override
  Future<AppSettings> getSettings() async {
    final db = await database;
    final maps = await db.query('app_settings');
    if (maps.isEmpty) return AppSettings();
    return AppSettings.fromMap(maps.first);
  }

  // Clear all data
  @override
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('focus_sessions');
    await db.delete('tasks');
    await db.delete('daily_records');
    await db.delete('spacetimes');
    await db.delete('achievements');
    await db.delete('app_settings');
  }
}
