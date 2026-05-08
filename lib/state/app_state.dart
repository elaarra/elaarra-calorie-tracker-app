import 'package:flutter/material.dart';
import '../screens/log/log_screen.dart';
import '../screens/goals/goals_screen.dart';
import '../services/database_service.dart';

class AppState extends ChangeNotifier {
  // ── User profile ──────────────────────────────────────────
  String userName = 'there';
  int dailyTarget = 1650;
  bool isPremium  = false;
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  // ── In-memory data (mirrored from SQLite) ─────────────────
  final Map<String, List<LogEntry>> _allEntries = {};
  final List<WeightEntry> weightLog = [];
  final List<Goal> goals = [];

  // ── Date helper ───────────────────────────────────────────
  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ── Initialise — load everything from SQLite ──────────────
  Future<void> init() async {
    final db = DatabaseService.instance;

    // Load profile
    final profile = await db.getProfile();
    if (profile != null) {
      userName    = profile['user_name'] as String;
      dailyTarget = profile['daily_target'] as int;
      isPremium   = (profile['is_premium'] as int) == 1;
    }

    // Load entries
    final entries = await db.getAllEntries();
    _allEntries.addAll(entries);

    // Load weight
    final weights = await db.getAllWeightEntries();
    weightLog.addAll(weights);

    // Load goals
    final loadedGoals = await db.getAllGoals();
    goals.addAll(loadedGoals);

    _isLoading = false;
    notifyListeners();
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

  // ── Streak ────────────────────────────────────────────────
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

  // ── Averages ──────────────────────────────────────────────
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

  // ── Calorie history for chart ─────────────────────────────
  List<Map<String, dynamic>> get calorieHistory {
    return List.generate(14, (i) {
      final date     = DateTime.now().subtract(Duration(days: 13 - i));
      final entries  = entriesFor(date);
      final consumed = entries.fold(0, (sum, e) => sum + e.calories);
      return {'date': date, 'consumed': consumed, 'target': dailyTarget};
    });
  }

  // ── Current weight ────────────────────────────────────────
  double? get currentWeight =>
      weightLog.isNotEmpty ? weightLog.last.weight : null;

  // ── Affirmation ───────────────────────────────────────────
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

  // ── Encouragement ─────────────────────────────────────────
  String get encouragement {
    if (isOverToday) return 'Every day is a fresh start — tomorrow is yours to own.';
    final pct = todayProgress * 100;
    if (pct >= 90) return 'Almost there. You\'ve been intentional today — finish strong.';
    if (pct >= 60) return 'You\'re right where you need to be. Stay the course.';
    return 'A great start. Your consistency is building something real.';
  }

  // ── Add log entry — saves to SQLite immediately ───────────
  Future<void> addEntry(DateTime date, LogEntry entry) async {
    final key = _dateKey(date);
    _allEntries.putIfAbsent(key, () => []);
    _allEntries[key]!.add(entry);
    await DatabaseService.instance.insertLogEntry(date, entry);
    notifyListeners();
  }

  // ── Delete log entry ──────────────────────────────────────
  Future<void> deleteEntry(DateTime date, int index) async {
    final key = _dateKey(date);
    if (_allEntries[key] != null && index < _allEntries[key]!.length) {
      _allEntries[key]!.removeAt(index);
      await DatabaseService.instance.deleteLogEntry(date, index);
      notifyListeners();
    }
  }

  // ── Add weight entry ──────────────────────────────────────
  Future<void> addWeight(WeightEntry entry) async {
    weightLog.add(entry);
    await DatabaseService.instance.insertWeightEntry(entry);
    notifyListeners();
  }

  // ── Add goal ──────────────────────────────────────────────
  Future<void> addGoal(Goal goal) async {
    goals.add(goal);
    await DatabaseService.instance.insertGoal(goal);
    notifyListeners();
  }

  // ── Update profile ────────────────────────────────────────
  Future<void> updateUserName(String name) async {
    userName = name;
    await _saveProfile();
    notifyListeners();
  }

  Future<void> updateDailyTarget(int target) async {
    dailyTarget = target;
    await _saveProfile();
    notifyListeners();
  }

  Future<void> setOnboardingComplete() async {
    await DatabaseService.instance.setOnboardingComplete();
  }

  Future<void> updateProfileFromOnboarding({
    required String name,
    required int target,
  }) async {
    userName    = name;
    dailyTarget = target;
    await DatabaseService.instance.saveProfile(
      userName: name,
      dailyTarget: target,
      isPremium: isPremium,
      onboardingComplete: true,
    );
    notifyListeners();
  }

  Future<void> togglePremium() async {
    isPremium = !isPremium;
    await _saveProfile();
    notifyListeners();
  }

  Future<void> _saveProfile() async {
    await DatabaseService.instance.saveProfile(
      userName: userName,
      dailyTarget: dailyTarget,
      isPremium: isPremium,
      onboardingComplete: true,
    );
  }
}
