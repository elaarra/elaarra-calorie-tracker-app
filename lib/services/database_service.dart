import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../screens/log/log_screen.dart';
import '../screens/goals/goals_screen.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('elaarra.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // User profile table
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY,
        user_name TEXT NOT NULL,
        daily_target INTEGER NOT NULL,
        is_premium INTEGER NOT NULL DEFAULT 0,
        onboarding_complete INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Log entries table
    await db.execute('''
      CREATE TABLE log_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        calories INTEGER NOT NULL,
        name TEXT,
        label TEXT,
        logged_at TEXT NOT NULL,
        date_key TEXT NOT NULL
      )
    ''');

    // Weight entries table
    await db.execute('''
      CREATE TABLE weight_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        logged_at TEXT NOT NULL
      )
    ''');

    // Goals table
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        target_weight REAL NOT NULL,
        starting_weight REAL NOT NULL,
        started_at TEXT NOT NULL,
        weekly_rate REAL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Insert default profile
    await db.insert('user_profile', {
      'id': 1,
      'user_name': 'there',
      'daily_target': 1650,
      'is_premium': 0,
      'onboarding_complete': 0,
    });
  }

  // ── User profile ──────────────────────────────────────────
  Future<Map<String, dynamic>?> getProfile() async {
    final db   = await database;
    final rows = await db.query('user_profile', where: 'id = ?', whereArgs: [1]);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<void> saveProfile({
    required String userName,
    required int dailyTarget,
    required bool isPremium,
    required bool onboardingComplete,
  }) async {
    final db = await database;
    await db.update(
      'user_profile',
      {
        'user_name': userName,
        'daily_target': dailyTarget,
        'is_premium': isPremium ? 1 : 0,
        'onboarding_complete': onboardingComplete ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> setOnboardingComplete() async {
    final db = await database;
    await db.update(
      'user_profile',
      {'onboarding_complete': 1},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<bool> isOnboardingComplete() async {
    final profile = await getProfile();
    if (profile == null) return false;
    return profile['onboarding_complete'] == 1;
  }

  // ── Log entries ───────────────────────────────────────────
  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> insertLogEntry(DateTime date, LogEntry entry) async {
    final db = await database;
    await db.insert('log_entries', {
      'calories': entry.calories,
      'name': entry.name,
      'label': entry.label,
      'logged_at': entry.loggedAt.toIso8601String(),
      'date_key': dateKey(date),
    });
  }

  Future<List<LogEntry>> getEntriesForDate(DateTime date) async {
    final db   = await database;
    final rows = await db.query(
      'log_entries',
      where: 'date_key = ?',
      whereArgs: [dateKey(date)],
      orderBy: 'logged_at ASC',
    );
    return rows.map((r) => LogEntry(
      calories: r['calories'] as int,
      name: r['name'] as String?,
      label: r['label'] as String?,
      loggedAt: DateTime.parse(r['logged_at'] as String),
    )).toList();
  }

  Future<Map<String, List<LogEntry>>> getAllEntries() async {
    final db   = await database;
    final rows = await db.query('log_entries', orderBy: 'logged_at ASC');
    final Map<String, List<LogEntry>> result = {};
    for (final r in rows) {
      final key   = r['date_key'] as String;
      final entry = LogEntry(
        calories: r['calories'] as int,
        name: r['name'] as String?,
        label: r['label'] as String?,
        loggedAt: DateTime.parse(r['logged_at'] as String),
      );
      result.putIfAbsent(key, () => []);
      result[key]!.add(entry);
    }
    return result;
  }

  Future<void> deleteLogEntry(DateTime date, int index) async {
    final db      = await database;
    final entries = await getEntriesForDate(date);
    if (index >= entries.length) return;
    final target = entries[index];
    await db.delete(
      'log_entries',
      where: 'date_key = ? AND logged_at = ?',
      whereArgs: [dateKey(date), target.loggedAt.toIso8601String()],
    );
  }

  // ── Weight entries ────────────────────────────────────────
  Future<void> insertWeightEntry(WeightEntry entry) async {
    final db = await database;
    await db.insert('weight_entries', {
      'weight': entry.weight,
      'logged_at': entry.loggedAt.toIso8601String(),
    });
  }

  Future<List<WeightEntry>> getAllWeightEntries() async {
    final db   = await database;
    final rows = await db.query('weight_entries', orderBy: 'logged_at ASC');
    return rows.map((r) => WeightEntry(
      weight: r['weight'] as double,
      loggedAt: DateTime.parse(r['logged_at'] as String),
    )).toList();
  }

  // ── Goals ─────────────────────────────────────────────────
  Future<void> insertGoal(Goal goal) async {
    final db = await database;
    await db.insert('goals', {
      'type': goal.type,
      'target_weight': goal.targetWeight,
      'starting_weight': goal.startingWeight,
      'started_at': goal.startedAt.toIso8601String(),
      'weekly_rate': goal.weeklyRate,
      'is_active': goal.isActive ? 1 : 0,
    });
  }

  Future<List<Goal>> getAllGoals() async {
    final db   = await database;
    final rows = await db.query('goals', orderBy: 'started_at ASC');
    return rows.map((r) => Goal(
      type: r['type'] as String,
      targetWeight: r['target_weight'] as double,
      startingWeight: r['starting_weight'] as double,
      startedAt: DateTime.parse(r['started_at'] as String),
      weeklyRate: r['weekly_rate'] as double?,
      isActive: (r['is_active'] as int) == 1,
    )).toList();
  }

  // ── Close db ──────────────────────────────────────────────
  Future close() async {
    final db = await database;
    db.close();
  }
}
