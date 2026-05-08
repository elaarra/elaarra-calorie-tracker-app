import 'package:flutter/material.dart';
import '../screens/log/log_screen.dart';
import '../screens/goals/goals_screen.dart';

class AppState extends ChangeNotifier {
  // ── User profile ──────────────────────────────────────────
  String userName        = 'Ella';
  int dailyTarget        = 1650;
  bool isPremium         = false;

  // ── Log entries keyed by date yyyy-MM-dd ──────────────────
  final Map<String, List<LogEntry>> _allEntries = {
    _dateKey(DateTime.now()): [
      LogEntry(
        calories: 320,
        name: 'Porridge with berries',
        label: 'Breakfast',
        loggedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      LogEntry(
        calories: 480,
        name: 'Grilled chicken salad',
        label: 'Lunch',
        loggedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      LogEntry(
        calories: 140,
        name: 'Greek yoghurt',
        label: 'Snack',
        loggedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
  };

  // ── Weight log ────────────────────────────────────────────
  final List<WeightEntry> weightLog = [
    WeightEntry(
      weight: 68.0,
      loggedAt: DateTime.now().subtract(const Duration(days: 42)),
    ),
    WeightEntry(
      weight: 67.2,
      loggedAt: DateTime.now().subtract(const Duration(days: 28)),
    ),
    WeightEntry(
      weight: 66.5,
      loggedAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    WeightEntry(
      weight: 65.6,
      loggedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  // ── Goals ─────────────────────────────────────────────────
  final List<Goal> goals = [
    Goal(
      type: 'Manage weight',
      targetWeight: 62,
      startingWeight: 68,
      startedAt: DateTime.now().subtract(const Duration(days: 42)),
      weeklyRate: 0.4,
    ),
  ];

  // ── Date helper ───────────────────────────────────────────
  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ── Entries for a given day ───────────────────────────────
  List<LogEntry> entriesFor(DateTime date) =>
      _allEntries[_dateKey(date)] ?? [];

  // ── Today's entries ───────────────────────────────────────
  List<LogEntry> get todayEntries => entriesFor(DateTime.now());

  // ── Today's consumed calories ─────────────────────────────
  int get todayConsumed =>
      todayEntries.fold(0, (sum, e) => sum + e.calories);

  // ── Today's remaining calories ────────────────────────────
  int get todayRemaining =>
      (dailyTarget - todayConsumed).clamp(0, dailyTarget);

  // ── Is over target today ──────────────────────────────────
  bool get isOverToday => todayConsumed > dailyTarget;

  // ── Today's progress 0.0–1.0 ─────────────────────────────
  double get todayProgress =>
      (todayConsumed / dailyTarget).clamp(0.0, 1.0);

  // ── Streak — consecutive days with at least one entry ─────
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

  // ── Average calories over all tracked days ────────────────
  double get avgCalories {
    final days = _allEntries.values.where((e) => e.isNotEmpty).toList();
    if (days.isEmpty) return 0;
    final total = days.fold<int>(
      0, (sum, entries) => sum + entries.fold(0, (s, e) => s + e.calories),
    );
    return total / days.length;
  }

  // ── Days tracked ──────────────────────────────────────────
  int get daysTracked =>
      _allEntries.values.where((e) => e.isNotEmpty).length;

  // ── Calorie history for chart (last 14 days) ──────────────
  List<Map<String, dynamic>> get calorieHistory {
    return List.generate(14, (i) {
      final date    = DateTime.now().subtract(Duration(days: 13 - i));
      final entries = entriesFor(date);
      final consumed = entries.fold(0, (sum, e) => sum + e.calories);
      return {
        'date': date,
        'consumed': consumed,
        'target': dailyTarget,
      };
    });
  }

  // ── Add a log entry ───────────────────────────────────────
  void addEntry(DateTime date, LogEntry entry) {
    final key = _dateKey(date);
    _allEntries.putIfAbsent(key, () => []);
    _allEntries[key]!.add(entry);
    notifyListeners();
  }

  // ── Delete a log entry ────────────────────────────────────
  void deleteEntry(DateTime date, int index) {
    final key = _dateKey(date);
    if (_allEntries[key] != null && index < _allEntries[key]!.length) {
      _allEntries[key]!.removeAt(index);
      notifyListeners();
    }
  }

  // ── Add a weight entry ────────────────────────────────────
  void addWeight(WeightEntry entry) {
    weightLog.add(entry);
    notifyListeners();
  }

  // ── Add a goal ────────────────────────────────────────────
  void addGoal(Goal goal) {
    goals.add(goal);
    notifyListeners();
  }

  // ── Current weight (latest logged) ───────────────────────
  double? get currentWeight =>
      weightLog.isNotEmpty ? weightLog.last.weight : null;

  // ── Affirmation based on avg vs target ───────────────────
  String get affirmation {
    if (daysTracked == 0) {
      return 'Welcome to elaarra. Every journey starts with a single day.';
    }
    final pct = avgCalories / dailyTarget;
    if (pct <= 0.85) {
      return 'Steady and considered. Your consistency is quietly doing the work.';
    } else if (pct <= 0.95) {
      return 'Right in the zone. This is what progress looks like.';
    } else if (pct <= 1.05) {
      return 'Beautifully balanced. You\'re honouring your goal every day.';
    }
    return 'A rich few days. Every day is a fresh opportunity — you\'ve got this.';
  }

  // ── Encouragement for home screen ────────────────────────
  String get encouragement {
    if (isOverToday) {
      return 'Every day is a fresh start — tomorrow is yours to own.';
    }
    final pct = todayProgress * 100;
    if (pct >= 90) {
      return 'Almost there. You\'ve been intentional today — finish strong.';
    } else if (pct >= 60) {
      return 'You\'re right where you need to be. Stay the course.';
    }
    return 'A great start. Your consistency is building something real.';
  }

  // ── Update daily target ───────────────────────────────────
  void updateDailyTarget(int target) {
    dailyTarget = target;
    notifyListeners();
  }

  // ── Update user name ──────────────────────────────────────
  void updateUserName(String name) {
    userName = name;
    notifyListeners();
  }

  // ── Toggle premium (for testing) ─────────────────────────
  void togglePremium() {
    isPremium = !isPremium;
    notifyListeners();
  }
}
