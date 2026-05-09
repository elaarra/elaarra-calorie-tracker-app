import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/log/log_screen.dart';
import '../screens/goals/goals_screen.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();
  FirestoreService._init();

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── User profile ──────────────────────────────────────────
  Future<void> saveProfile({
    required String userName,
    required int dailyTarget,
    required bool isPremium,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set({
        'userName': userName,
        'dailyTarget': dailyTarget,
        'isPremium': isPremium,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail — local data is still safe
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  // ── Log entries ───────────────────────────────────────────
  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> saveLogEntry(DateTime date, LogEntry entry) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('log_entries')
          .add({
        'calories': entry.calories,
        'name': entry.name,
        'label': entry.label,
        'loggedAt': entry.loggedAt.toIso8601String(),
        'dateKey': _dateKey(date),
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> deleteLogEntry(DateTime date, DateTime loggedAt) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('log_entries')
          .where('dateKey', isEqualTo: _dateKey(date))
          .where('loggedAt', isEqualTo: loggedAt.toIso8601String())
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<Map<String, List<LogEntry>>> getAllLogEntries() async {
    final uid = _uid;
    if (uid == null) return {};
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('log_entries')
          .orderBy('loggedAt')
          .get();
      final Map<String, List<LogEntry>> result = {};
      for (final doc in snap.docs) {
        final data  = doc.data();
        final key   = data['dateKey'] as String;
        final entry = LogEntry(
          calories: data['calories'] as int,
          name: data['name'] as String?,
          label: data['label'] as String?,
          loggedAt: DateTime.parse(data['loggedAt'] as String),
        );
        result.putIfAbsent(key, () => []);
        result[key]!.add(entry);
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  // ── Weight entries ────────────────────────────────────────
  Future<void> saveWeightEntry(WeightEntry entry) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('weight_entries')
          .add({
        'weight': entry.weight,
        'loggedAt': entry.loggedAt.toIso8601String(),
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<List<WeightEntry>> getAllWeightEntries() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('weight_entries')
          .orderBy('loggedAt')
          .get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return WeightEntry(
          weight: (data['weight'] as num).toDouble(),
          loggedAt: DateTime.parse(data['loggedAt'] as String),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Goals ─────────────────────────────────────────────────
  Future<void> saveGoal(Goal goal) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('goals')
          .add({
        'type': goal.type,
        'targetWeight': goal.targetWeight,
        'startingWeight': goal.startingWeight,
        'startedAt': goal.startedAt.toIso8601String(),
        'weeklyRate': goal.weeklyRate,
        'isActive': goal.isActive,
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<List<Goal>> getAllGoals() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('goals')
          .orderBy('startedAt')
          .get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return Goal(
          type: data['type'] as String,
          targetWeight: (data['targetWeight'] as num).toDouble(),
          startingWeight: (data['startingWeight'] as num).toDouble(),
          startedAt: DateTime.parse(data['startedAt'] as String),
          weeklyRate: data['weeklyRate'] != null
              ? (data['weeklyRate'] as num).toDouble()
              : null,
          isActive: data['isActive'] as bool? ?? true,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Clear all user data ───────────────────────────────────
  Future<void> clearAllData() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final collections = ['log_entries', 'weight_entries', 'goals'];
      for (final col in collections) {
        final snap = await _db
            .collection('users')
            .doc(uid)
            .collection(col)
            .get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      }
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      // Silently fail
    }
  }

  // ── Pull all data from Firestore into local ───────────────
  // Called on login — returns all cloud data for the app to load
  Future<Map<String, dynamic>> pullAllData() async {
    final uid = _uid;
    if (uid == null) return {};
    try {
      final profile     = await getProfile();
      final logEntries  = await getAllLogEntries();
      final weights     = await getAllWeightEntries();
      final goals       = await getAllGoals();
      return {
        'profile':    profile,
        'logEntries': logEntries,
        'weights':    weights,
        'goals':      goals,
      };
    } catch (e) {
      return {};
    }
  }
}
