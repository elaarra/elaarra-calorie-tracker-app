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

  // ── Init — loads from Firestore if valid, else SQLite ─────
  Future<void> init() async {
    final db        = DatabaseService.instance;
    final firestore = FirestoreService.instance;

    // Load local data first
    final localProfile = await db.getProfile();
    final localOnboardingDone = localProfile != null &&
        (localProfile['onboarding_complete'] as int) == 1;
    final localName = localProfile?['user_name'] as String? ?? 'there';

    // Try Firestore
    final cloudData = await firestore.pullAllData();
    final cloudProfile = cloudData['profile'] as Map<String, dynamic>?;
    final cloudName = cloudProfile?['userName'] as String? ?? 'there';

    // Only use cloud data if it has meaningful profile data
    // i.e. the user has actually completed onboarding on another device
    final cloudIsValid = cloudProfile != null &&
        cloudName != 'there' &&
        cloudName.isNotEmpty;

    // Prefer cloud if valid AND local hasn't been personalised yet
    final useCloud = cloudIsValid && !localOnboardingDone;

    if (useCloud) {
      // Cloud data is more complete — use it
      userName    = cloudName;
      dailyTarget = cloudProfile['dailyTarget'] as int? ?? 1650;
      isPremium   = cloudProfile['isPremium'] as bool? ?? false;

      final cloudEntries = cloudData['logEntries']
          as Map<String, List<LogEntry>>? ?? {};
      _allEntries.addAll(cloudEntries);

      final cloudWeights = cloudData['weights'] as List<WeightEntry>? ?? [];
      weightLog.addAll(cloudWeights);

      final cloudGoals = cloudData['goals'] as List<Goal>? ?? [];
      goals.addAll(cloudGoals);

      // Sync cloud down to local SQLite
      await _syncCloudToLocal(db, cloudEntries, cloudWeights, cloudGoals);

    } else {
      // Use local data — it's either more up to date or cloud has nothing useful
      if (localProfile != null) {
        userName    = localProfile['user_name'] as String;
        dailyTarget = localProfile['daily_target'] as int;
        isPremium   = (localProfile['is_premium'] as int) == 1;
      }
      final entries = await db.getAllEntries();
      _allEntries.addAll(entries);
      final weights = await db.getAllWeightEntries();
      weightLog.addAll(weights);
      final loadedGoals = await db.getAllGoals();
      goals.addAll(loadedGoals);

      // If local has real data, push it up to Firestore to keep in sync
      if (localOnboardingDone) {
        _pushLocalToCloud(entries, weights, loadedGoals);
      }
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
      // Local sync failed — cloud data still in memory
    }
  }

  void _pushLocalToCloud(
    Map<String, List<LogEntry>> entries,
    List<WeightEntry> weights,
    List<Goal> goals,
  ) async {
    try {
      final firestore = FirestoreService.instance;
      firestore.saveProfile(
        userName: userName,
        dailyTarget: dailyTarget,
        isPremium: isPremium,
      );
      for (final entry in entries.entries) {
        final date = DateTime.parse(entry.key);
        for (final log in entry.value) {
          firestore.saveLogEntry(date, log);
        }
      }
      for (final w in weights) {
        firestore.saveWeightEntry(w);
      }
      for (final g in goals) {
        firestore.saveGoal(g);
      }
    } catch (e) {
      // Background push failed silently
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

  // ── Add log entry ─────────────────────────────────────────
  Future<void> addEntry(DateTime date, LogEntry entry) async {
    final key = _dateKey(date);
    _allEntries.putIfAbsent(key, () => []);
    _allEntries[key]!.add(entry);
    notifyListeners();
    await DatabaseService.instance.insertLogEntry(date, entry);
    FirestoreService.instance.saveLogEntry(date, entry);
  }

  // ── Delete log entry ──────────────────────────────────────
  Future<void> deleteEntry(DateTime date, int index) async {
    final key = _dateKey(date);
    if (_allEntries[key] != null && index < _allEntries[key]!.length) {
      final entry = _allEntries[key]![index];
      _allEntries[key]!.removeAt(index);
      notifyListeners();
      await DatabaseService.instance.deleteLogEntry(date, index);
      FirestoreService.instance.deleteLogEntry(date, entry.loggedAt);
    }
  }

  // ── Add weight ────────────────────────────────────────────
  Future<void> addWeight(WeightEntry entry) async {
    weightLog.add(entry);
    notifyListeners();
    await DatabaseService.instance.insertWeightEntry(entry);
    FirestoreService.instance.saveWeightEntry(entry);
  }

  // ── Add goal ──────────────────────────────────────────────
  Future<void> addGoal(Goal goal) async {
    goals.add(goal);
    notifyListeners();
    await DatabaseService.instance.insertGoal(goal);
    FirestoreService.instance.saveGoal(goal);
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
    FirestoreService.instance.clearAllData();
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
