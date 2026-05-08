import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme.dart';

// ── Data models ───────────────────────────────────────────────
class Goal {
  final String type;
  final double targetWeight;
  final double startingWeight;
  final DateTime startedAt;
  final double? weeklyRate;
  final String approach; // 'rate' only now — no end date
  bool isActive;

  Goal({
    required this.type,
    required this.targetWeight,
    required this.startingWeight,
    required this.startedAt,
    this.weeklyRate,
    required this.approach,
    this.isActive = true,
  });
}

class WeightEntry {
  final double weight;
  final DateTime loggedAt;

  WeightEntry({required this.weight, required this.loggedAt});
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  // ── Hardcoded for now ─────────────────────────────────────
  final bool _isPremium = false;

  final List<Goal> _goals = [
    Goal(
      type: 'Manage weight',
      targetWeight: 62,
      startingWeight: 68,
      startedAt: DateTime.now().subtract(const Duration(days: 42)),
      weeklyRate: 0.4,
      approach: 'rate',
    ),
  ];

  final List<WeightEntry> _weightLog = [
    WeightEntry(weight: 68.0, loggedAt: DateTime.now().subtract(const Duration(days: 42))),
    WeightEntry(weight: 67.2, loggedAt: DateTime.now().subtract(const Duration(days: 28))),
    WeightEntry(weight: 66.5, loggedAt: DateTime.now().subtract(const Duration(days: 14))),
    WeightEntry(weight: 65.6, loggedAt: DateTime.now().subtract(const Duration(days: 3))),
  ];

  // ── Calorie progress (hardcoded — will come from shared state later) ──
  final int _dailyTarget   = 1650;
  final int _todayConsumed = 1240;
  final int _streakDays    = 7;
  final int _daysTracked   = 42;
  final double _avgCalories = 1580;

  final List<String> _goalTypes = [
    'Manage weight',
    'Build muscle',
    'Maintain lifestyle',
  ];

  void _openNewGoal() {
    if (!_isPremium && _goals.isNotEmpty) {
      _showPremiumNudge();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewGoalSheet(
        goalTypes: _goalTypes,
        onSubmit: (goal) => setState(() => _goals.add(goal)),
      ),
    );
  }

  void _openWeightLog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WeightLogSheet(
        weightLog: _weightLog,
        onAdd: (entry) => setState(() => _weightLog.add(entry)),
      ),
    );
  }

  void _showPremiumNudge() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          gradient: AppGradient.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.blush, width: 0.3)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36, height: 3,
                decoration: BoxDecoration(
                  color: AppColors.blush.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.auto_awesome, color: AppColors.blush, size: 28),
            const SizedBox(height: 12),
            Text(
              'Multiple goals with premium',
              style: AppTextStyles.titleLarge.copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Upgrade to track multiple goals at once and unlock AI food analysis.',
              style: AppTextStyles.body.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Unlock premium — £4.99/mo',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.button,
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Text(
                'Maybe later',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.background),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildCalorieProgress(),
              const SizedBox(height: 16),
              _buildStreakAndAverage(),
              const SizedBox(height: 16),
              if (_goals.isNotEmpty) ...[
                ..._goals.map((g) => _buildGoalCard(g)),
                const SizedBox(height: 4),
              ],
              _buildWeightSection(),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _openNewGoal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('+ New goal', style: AppTextStyles.button),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('your results', style: AppTextStyles.body),
        Text(
          'How you\'re\ndoing',
          style: AppTextStyles.titleLarge.copyWith(fontSize: 40),
        ),
      ],
    );
  }

  // ── Calorie progress ──────────────────────────────────────
  Widget _buildCalorieProgress() {
    final progress = (_todayConsumed / _dailyTarget).clamp(0.0, 1.0);
    final isOver   = _todayConsumed > _dailyTarget;
    final pct      = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY\'S CALORIES',
            style: AppTextStyles.caption.copyWith(letterSpacing: 0.14),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_todayConsumed',
                    style: AppTextStyles.titleLarge.copyWith(fontSize: 36),
                  ),
                  Text(
                    'of $_dailyTarget kcal',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isOver
                      ? AppColors.sienna.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOver ? 'Over goal' : '$pct% of goal',
                  style: AppTextStyles.caption.copyWith(
                    color: isOver ? AppColors.sienna : AppColors.cream,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? AppColors.sienna : AppColors.cream,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Streak and average ────────────────────────────────────
  Widget _buildStreakAndAverage() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Day streak',
            value: '$_streakDays',
            sub: 'days logged in a row',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            label: 'Avg calories',
            value: '${_avgCalories.round()}',
            sub: 'over $_daysTracked days',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              fontSize: 9, letterSpacing: 0.12,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.titleLarge.copyWith(fontSize: 28)),
          Text(
            sub,
            style: AppTextStyles.caption.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ── Goal card ─────────────────────────────────────────────
  Widget _buildGoalCard(Goal goal) {
    final weightDiff   = (goal.startingWeight - goal.targetWeight).abs();
    final currentWeight = _weightLog.isNotEmpty
        ? _weightLog.last.weight
        : goal.startingWeight;
    final weightChanged = (goal.startingWeight - currentWeight).abs();
    final progress      = weightDiff == 0
        ? 0.0
        : (weightChanged / weightDiff).clamp(0.0, 1.0);
    final pct           = (progress * 100).round();
    final remaining     = (goal.targetWeight - currentWeight).abs();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.type.toUpperCase(),
                style: AppTextStyles.caption.copyWith(letterSpacing: 0.12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  goal.weeklyRate != null
                      ? '${goal.weeklyRate}kg / week'
                      : 'Ongoing',
                  style: AppTextStyles.caption.copyWith(fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.startingWeight}kg → ${goal.targetWeight}kg',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.cream, fontSize: 13,
                ),
              ),
              Text(
                '$pct%',
                style: AppTextStyles.titleLarge.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cream),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGoalStat(
                'changed',
                '${weightChanged.toStringAsFixed(1)}kg',
              ),
              Container(
                width: 0.5, height: 28,
                color: AppColors.blush.withOpacity(0.3),
              ),
              _buildGoalStat(
                'to go',
                '${remaining.toStringAsFixed(1)}kg',
              ),
              Container(
                width: 0.5, height: 28,
                color: AppColors.blush.withOpacity(0.3),
              ),
              _buildGoalStat(
                'started',
                '${DateTime.now().difference(goal.startedAt).inDays}d ago',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.titleLarge.copyWith(fontSize: 18)),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(fontSize: 9),
        ),
      ],
    );
  }

  // ── Weight section ────────────────────────────────────────
  Widget _buildWeightSection() {
    final latest = _weightLog.isNotEmpty ? _weightLog.last : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WEIGHT',
                style: AppTextStyles.caption.copyWith(letterSpacing: 0.14),
              ),
              GestureDetector(
                onTap: _openWeightLog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.blush.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '+ Log weight',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10, color: AppColors.cream,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Optional — log whenever feels right.',
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: AppColors.blush.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 14),
          latest == null
              ? Text(
                  'No weight logged yet.',
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                )
              : Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${latest.weight}kg',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontSize: 32,
                          ),
                        ),
                        Text(
                          'Last logged · ${_formatDate(latest.loggedAt)}',
                          style: AppTextStyles.caption.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (_weightLog.length > 1) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Started at',
                            style: AppTextStyles.caption.copyWith(fontSize: 9),
                          ),
                          Text(
                            '${_weightLog.first.weight}kg',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            '${(_weightLog.first.weight - latest.weight).abs().toStringAsFixed(1)}kg ${latest.weight < _weightLog.first.weight ? 'down' : 'up'}',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: AppColors.cream,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    return '$diff days ago';
  }
}

// ── New goal sheet ────────────────────────────────────────────
class _NewGoalSheet extends StatefulWidget {
  final List<String> goalTypes;
  final Function(Goal) onSubmit;

  const _NewGoalSheet({required this.goalTypes, required this.onSubmit});

  @override
  State<_NewGoalSheet> createState() => _NewGoalSheetState();
}

class _NewGoalSheetState extends State<_NewGoalSheet> {
  String _selectedType     = 'Manage weight';
  String _approach         = 'rate'; // only approach now
  final _targetController  = TextEditingController();
  final _rateController    = TextEditingController(text: '0.5');

  void _submit() {
    final target = double.tryParse(_targetController.text);
    final rate   = double.tryParse(_rateController.text);
    if (target == null) return;

    widget.onSubmit(Goal(
      type: _selectedType,
      targetWeight: target,
      startingWeight: 68, // TODO: pull from user profile
      startedAt: DateTime.now(),
      weeklyRate: rate,
      approach: _approach,
    ));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _targetController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppGradient.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.blush, width: 0.3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.blush.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Let\'s set\nyour goal',
                style: AppTextStyles.titleLarge.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 20),

              // Goal type
              Text(
                'GOAL TYPE',
                style: AppTextStyles.caption.copyWith(letterSpacing: 0.14),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: widget.goalTypes.map((t) {
                  final sel = _selectedType == t;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.cream
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? AppColors.cream
                              : AppColors.blush.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        t,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12,
                          color: sel ? AppColors.darkBrown : AppColors.blush,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Target weight
              Text(
                'TARGET WEIGHT (OPTIONAL)',
                style: AppTextStyles.caption.copyWith(letterSpacing: 0.14),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _targetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppTextStyles.inputValue.copyWith(
                          color: AppColors.darkBrown, fontSize: 32,
                        ),
                        decoration: InputDecoration(
                          hintText: '—',
                          hintStyle: AppTextStyles.inputValue.copyWith(
                            color: AppColors.blush.withOpacity(0.4),
                            fontSize: 32,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Text(
                      'kg',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.sienna, fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Weekly rate
              Text(
                'WEEKLY RATE (OPTIONAL)',
                style: AppTextStyles.caption.copyWith(letterSpacing: 0.14),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppTextStyles.inputValue.copyWith(
                          color: AppColors.darkBrown, fontSize: 32,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Text(
                      'kg / week',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.sienna, fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This informs your calorie target — not a deadline.',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: AppColors.blush.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

              // Submit
              GestureDetector(
                onTap: _submit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Set goal',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.button,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Weight log sheet ──────────────────────────────────────────
class _WeightLogSheet extends StatefulWidget {
  final List<WeightEntry> weightLog;
  final Function(WeightEntry) onAdd;

  const _WeightLogSheet({required this.weightLog, required this.onAdd});

  @override
  State<_WeightLogSheet> createState() => _WeightLogSheetState();
}

class _WeightLogSheetState extends State<_WeightLogSheet> {
  final _controller = TextEditingController();

  void _submit() {
    final w = double.tryParse(_controller.text);
    if (w == null) return;
    widget.onAdd(WeightEntry(weight: w, loggedAt: DateTime.now()));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppGradient.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.blush, width: 0.3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 3,
                decoration: BoxDecoration(
                  color: AppColors.blush.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Log your\nweight',
              style: AppTextStyles.titleLarge.copyWith(fontSize: 34),
            ),
            const SizedBox(height: 4),
            Text(
              'Whenever feels right — no pressure to do this daily.',
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTextStyles.inputValue.copyWith(
                        fontSize: 48, color: AppColors.darkBrown,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.0',
                        hintStyle: AppTextStyles.inputValue.copyWith(
                          fontSize: 48,
                          color: AppColors.blush.withOpacity(0.4),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Text(
                    'kg',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.sienna, fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Save',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
