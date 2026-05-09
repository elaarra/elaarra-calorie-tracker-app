import 'package:flutter/material.dart';
import '../screens/log/log_screen.dart';
import '../screens/goals/goals_screen.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';

class AppState extends ChangeNotifier {
  String userName = 'there';
  int dailyTarget = 1650;
  bool isPremium  = false;
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  final Map<String, List<LogEntry>> _allEntries = {};
  final List<WeightEntry> weightLog = [];
  final List<Goal> goals = [];

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ── Init — loads from Firestore first, falls back to SQLite ──
  Future<void> init() async {
    final db        = DatabaseService.instance;
    final firestore = FirestoreService.instance;

    // Try Firestore first
    final cloudData = await firestore.pullAllData();

    if (cloudData.isNotEmpty) {
      // Cloud data found — use it and sync to local SQLite
      final profile = cloudData['profile'] as Map<String, dynamic>?;
      if (profile != null) {
        userName    = profile['userName'] as String? ?? 'there';
        dailyTarget = profile['dailyTarget'] as int? ?? 1650;
        isPremium   = profile['isPremium'] as bool? ?? false;
      }

      final cloudEntries = cloudData['logEntries']
          as Map<String, List<LogEntry>>? ?? {};
      _allEntries.addAll(cloudEntries);

      final cloudWeights = cloudData['weights'] as List<WeightEntry>? ?? [];
      weightLog.addAll(cloudWeights);

      final cloudGoals = cloudData['goals'] as List<Goal>? ?? [];
      goals.addAll(cloudGoals);

      // Save cloud data to local SQLite for offline use
      await _syncCloudToLocal(db, cloudEntries, cloudWeights, cloudGoals);

    } else {
      // No cloud data — load from local SQLite
      final profile = await db.getProfile();
      if (profile != null) {
        userName    = profile['user_name'] as String;
        dailyTarget = profile['daily_target'] as int;
        isPremium   = (profile['is_premium'] as int) == 1;
      }
      final entries = await db.getAllEntries();
      _allEntries.addAll(entries);
      final weights = await db.getAllWeightEntries();
      weightLog.addAll(weights);
      final loadedGoals = await db.getAllGoals();
      goals.addAll(loadedGoals);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _syncCloudToLocal(
    DatabaseService db,
    Map<String, List<LogEntry>> entries,
    List<WeightEntry> weights,
    List<Goal> goals,
  ) async {
    try {
      // Clear local and rewrite from cloud
      await db.clearAllData();
      await db.saveProfile(
        userName: userName,
        dailyTarget: dailyTarget,
        isPremium: isPremium,
        onboardingComplete: true,
      );
      for (final entry in entries.entries) {
        final date = DateTime.parse(entry.key);
        for (final log in entry.value) {
          await db.insertLogEntry(date, log);
        }
      }
      for (final w in weights) {
        await db.insertWeightEntry(w);
      }
      for (final g in goals) {
        await db.insertGoal(g);
      }
    } catch (e) {
      // Local sync failed — cloud data still in memory, app works fine
    }
  }

  // ── Entries ───────────────────────────────────────────────
  List<LogEntry> entriesFor(DateTime date) =>
      _allEntries[_dateKey(date)] ?? [];

  List<LogEntry> get todayEntries => entriesFor(DateTime.now());

  int get todayConsumed =>
      todayEntries.fold(0, (sum, e) => sum + e.calories);

  int get todayRemaining =>
      (dailyTarget - todayConsumed).clamp(0, dailyTarget);

  bool get isOverToday => todayConsumed > dailyTarget;

  double get todayProgress =>
      (todayConsumed / dailyTarget).clamp(0.0, 1.0);

  int get streakDays {
    int streak = 0;
    DateTime day = DateTime.now();
    while (true) {
      final entries = entriesFor(day);
      if (entries.isEmpty) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double get avgCalories {
    final days = _allEntries.values.where((e) => e.isNotEmpty).toList();
    if (days.isEmpty) return 0;
    final total = days.fold<int>(
      0, (sum, entries) => sum + entries.fold(0, (s, e) => s + e.calories),
    );
    return total / days.length;
  }

  int get daysTracked =>
      _allEntries.values.where((e) => e.isNotEmpty).length;

  List<Map<String, dynamic>> get calorieHistory {
    return List.generate(14, (i) {
      final date     = DateTime.now().subtract(Duration(days: 13 - i));
      final entries  = entriesFor(date);
      final consumed = entries.fold(0, (sum, e) => sum + e.calories);
      return {'date': date, 'consumed': consumed, 'target': dailyTarget};
    });
  }

  double? get currentWeight =>
      weightLog.isNotEmpty ? weightLog.last.weight : null;

  String get affirmation {
    if (daysTracked == 0) {
      return 'Welcome to elaarra. Every journey starts with a single day.';
    }
    final pct = avgCalories / dailyTarget;
    if (pct <= 0.85) return 'Steady and considered. Your consistency is quietly doing the work.';
    if (pct <= 0.95) return 'Right in the zone. This is what progress looks like.';
    if (pct <= 1.05) return 'Beautifully balanced. You\'re honouring your goal every day.';
    return 'A rich few days. Every day is a fresh opportunity — you\'ve got this.';
  }

  String get encouragement {
    if (isOverToday) return 'Every day is a fresh start — tomorrow is yours to own.';
    final pct = todayProgress * 100;
    if (pct >= 90) return 'Almost there. You\'ve been intentional today — finish strong.';
    if (pct >= 60) return 'You\'re right where you need to be. Stay the course.';
    return 'A great start. Your consistency is building something real.';
  }

  // ── Add log entry — saves locally and to Firestore ────────
  Future<void> addEntry(DateTime date, LogEntry entry) async {
    final key = _dateKey(date);
    _allEntries.putIfAbsent(key, () => []);
    _allEntries[key]!.add(entry);
    notifyListeners();
    await DatabaseService.instance.insertLogEntry(date, entry);
    FirestoreService.instance.saveLogEntry(date, entry); // background
  }

  // ── Delete log entry ──────────────────────────────────────
  Future<void> deleteEntry(DateTime date, int index) async {
    final key = _dateKey(date);
    if (_allEntries[key] != null && index < _allEntries[key]!.length) {
      final entry = _allEntries[key]![index];
      _allEntries[key]!.removeAt(index);
      notifyListeners();
      await DatabaseService.instance.deleteLogEntry(date, index);
      FirestoreService.instance.deleteLogEntry(date, entry.loggedAt); // background
    }
  }

  // ── Add weight ────────────────────────────────────────────
  Future<void> addWeight(WeightEntry entry) async {
    weightLog.add(entry);
    notifyListeners();
    await DatabaseService.instance.insertWeightEntry(entry);
    FirestoreService.instance.saveWeightEntry(entry); // background
  }

  // ── Add goal ──────────────────────────────────────────────
  Future<void> addGoal(Goal goal) async {
    goals.add(goal);
    notifyListeners();
    await DatabaseService.instance.insertGoal(goal);
    FirestoreService.instance.saveGoal(goal); // background
  }

  // ── Update profile ────────────────────────────────────────
  Future<void> updateUserName(String name) async {
    userName = name;
    notifyListeners();
    await _saveProfile();
  }

  Future<void> updateDailyTarget(int target) async {
    dailyTarget = target;
    notifyListeners();
    await _saveProfile();
  }

  Future<void> updateProfileFromOnboarding({
    required String name,
    required int target,
  }) async {
    userName    = name;
    dailyTarget = target;
    notifyListeners();
    await DatabaseService.instance.saveProfile(
      userName: name,
      dailyTarget: target,
      isPremium: isPremium,
      onboardingComplete: true,
    );
    FirestoreService.instance.saveProfile(
      userName: name,
      dailyTarget: target,
      isPremium: isPremium,
    );
  }

  Future<void> togglePremium() async {
    isPremium = !isPremium;
    notifyListeners();
    await _saveProfile();
  }

  // ── Reset all data ────────────────────────────────────────
  Future<void> resetAllData() async {
    _allEntries.clear();
    weightLog.clear();
    goals.clear();
    userName    = 'there';
    dailyTarget = 1650;
    isPremium   = false;
    notifyListeners();
    await DatabaseService.instance.clearAllData();
    FirestoreService.instance.clearAllData(); // background
  }

  Future<void> _saveProfile() async {
    await DatabaseService.instance.saveProfile(
      userName: userName,
      dailyTarget: dailyTarget,
      isPremium: isPremium,
      onboardingComplete: true,
    );
    FirestoreService.instance.saveProfile(
      userName: userName,
      dailyTarget: dailyTarget,
      isPremium: isPremium,
    );
  }
}
