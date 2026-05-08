import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../state/app_state.dart';

class Goal {
  final String type;
  final double targetWeight;
  final double startingWeight;
  final DateTime startedAt;
  final double? weeklyRate;
  bool isActive;

  Goal({
    required this.type,
    required this.targetWeight,
    required this.startingWeight,
    required this.startedAt,
    this.weeklyRate,
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
  final List<String> _goalTypes = [
    'Manage weight',
    'Build muscle',
    'Maintain lifestyle',
  ];

  void _openNewGoal(AppState state) {
    if (!state.isPremium && state.goals.isNotEmpty) {
      _showPremiumNudge();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewGoalSheet(
        goalTypes: _goalTypes,
        onSubmit: (goal) => state.addGoal(goal),
      ),
    );
  }

  void _openWeightLog(AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WeightLogSheet(
        onAdd: (entry) => state.addWeight(entry),
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
            Text('Multiple goals with premium', style: AppTextStyles.titleLarge.copyWith(fontSize: 24), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Upgrade to track multiple goals at once and unlock AI food analysis.', style: AppTextStyles.body.copyWith(fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
                child: Text('Unlock premium — £4.99/mo', textAlign: TextAlign.center, style: AppTextStyles.button),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Text('Maybe later', style: AppTextStyles.caption.copyWith(fontSize: 11), textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
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
              _buildAverageAndAffirmation(state),
              const SizedBox(height: 12),
              _buildStreakAndToday(state),
              const SizedBox(height: 12),
              _buildCalorieChart(state),
              const SizedBox(height: 12),
              _buildWeightSection(state),
              const SizedBox(height: 16),
              if (state.goals.isNotEmpty) ...[
                Text('YOUR GOALS', style: AppTextStyles.caption.copyWith(letterSpacing: 0.14)),
                const SizedBox(height: 8),
                ...state.goals.map((g) => _buildGoalCard(g, state)),
              ],
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: () => _openNewGoal(state),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                    decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('your results', style: AppTextStyles.body),
        Text('How you\'re\ndoing', style: AppTextStyles.titleLarge.copyWith(fontSize: 40)),
      ],
    );
  }

  Widget _buildAverageAndAffirmation(AppState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AVERAGE DAILY CALORIES', style: AppTextStyles.caption.copyWith(letterSpacing: 0.14)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${state.avgCalories.round()}', style: AppTextStyles.titleLarge.copyWith(fontSize: 48)),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 8),
                child: Text('kcal / day', style: AppTextStyles.caption),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('over ${state.daysTracked} days', style: AppTextStyles.caption.copyWith(fontSize: 10)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blush.withOpacity(0.15)),
            ),
            child: Text(
              state.affirmation,
              style: AppTextStyles.body.copyWith(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.cream),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakAndToday(AppState state) {
    final isOver    = state.isOverToday;
    final remaining = state.todayRemaining;
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            label: 'DAY STREAK',
            value: '${state.streakDays}',
            sub: 'days logged in a row',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoCard(
            label: 'TODAY',
            value: '${state.todayConsumed}',
            sub: isOver
                ? '${state.todayConsumed - state.dailyTarget} over goal'
                : '$remaining kcal remaining',
            subColor: isOver ? AppColors.sienna : null,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String label, required String value, required String sub, Color? subColor}) {
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
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9, letterSpacing: 0.12)),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.titleLarge.copyWith(fontSize: 30)),
          const SizedBox(height: 2),
          Text(sub, style: AppTextStyles.caption.copyWith(fontSize: 9, color: subColor ?? AppColors.blush)),
        ],
      ),
    );
  }

  Widget _buildCalorieChart(AppState state) {
    final history = state.calorieHistory;
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
          Text('CALORIES — ACTUAL VS TARGET', style: AppTextStyles.caption.copyWith(letterSpacing: 0.14)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _CalorieChartPainter(
                data: history,
                target: state.dailyTarget,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem('Actual', AppColors.cream, dashed: false),
              const SizedBox(width: 16),
              _buildLegendItem('Target', AppColors.blush.withOpacity(0.5), dashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {required bool dashed}) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: CustomPaint(
            size: const Size(20, 2),
            painter: _LegendLinePainter(color: color, dashed: dashed),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _buildWeightSection(AppState state) {
    final latest   = state.weightLog.isNotEmpty ? state.weightLog.last : null;
    final starting = state.weightLog.isNotEmpty ? state.weightLog.first : null;
    final target   = state.goals.isNotEmpty ? state.goals.first.targetWeight : null;

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
              Text('WEIGHT', style: AppTextStyles.caption.copyWith(letterSpacing: 0.14)),
              GestureDetector(
                onTap: () => _openWeightLog(state),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.blush.withOpacity(0.3)),
                  ),
                  child: Text('+ Log weight', style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.cream)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Optional — log whenever feels right.', style: AppTextStyles.caption.copyWith(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.blush.withOpacity(0.6))),
          const SizedBox(height: 16),
          latest == null
              ? Text('No weight logged yet.', style: AppTextStyles.body.copyWith(fontSize: 13))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeightStat('Current', '${latest.weight}kg'),
                    Container(width: 0.5, height: 36, color: AppColors.blush.withOpacity(0.3)),
                    _buildWeightStat('Starting', starting != null ? '${starting.weight}kg' : '—'),
                    Container(width: 0.5, height: 36, color: AppColors.blush.withOpacity(0.3)),
                    _buildWeightStat('Target', target != null ? '${target}kg' : '—'),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildWeightStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.titleLarge.copyWith(fontSize: 22)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9)),
      ],
    );
  }

  Widget _buildGoalCard(Goal goal, AppState state) {
    final weightDiff    = (goal.startingWeight - goal.targetWeight).abs();
    final currentWeight = state.weightLog.isNotEmpty ? state.weightLog.last.weight : goal.startingWeight;
    final weightChanged = (goal.startingWeight - currentWeight).abs();
    final progress      = weightDiff == 0 ? 0.0 : (weightChanged / weightDiff).clamp(0.0, 1.0);
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
              Text(goal.type.toUpperCase(), style: AppTextStyles.caption.copyWith(letterSpacing: 0.12)),
              if (goal.weeklyRate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('${goal.weeklyRate}kg / week', style: AppTextStyles.caption.copyWith(fontSize: 9)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${goal.startingWeight}kg → ${goal.targetWeight}kg', style: AppTextStyles.body.copyWith(color: AppColors.cream, fontSize: 13)),
              Text('$pct%', style: AppTextStyles.titleLarge.copyWith(fontSize: 18)),
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
              _buildGoalStat('changed', '${weightChanged.toStringAsFixed(1)}kg'),
              Container(width: 0.5, height: 28, color: AppColors.blush.withOpacity(0.3)),
              _buildGoalStat('to go', '${remaining.toStringAsFixed(1)}kg'),
              Container(width: 0.5, height: 28, color: AppColors.blush.withOpacity(0.3)),
              _buildGoalStat('started', '${DateTime.now().difference(goal.startedAt).inDays}d ago'),
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
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9)),
      ],
    );
  }
}

class _CalorieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final int target;

  _CalorieChartPainter({required this.data, required this.target});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final consumed = data.map((d) => d['consumed'] as int).toList();
    final maxVal   = consumed.reduce((a, b) => a > b ? a : b);
    final minVal   = consumed.reduce((a, b) => a < b ? a : b);
    final range    = (maxVal - minVal).toDouble() + 200;
    final bottom   = minVal.toDouble() - 100;

    double xOf(int i) => (i / (data.length - 1)) * size.width;
    double yOf(int v) => size.height - ((v - bottom) / range) * size.height;

    final targetY   = yOf(target);
    final dashPaint = Paint()
      ..color = AppColors.blush.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double dx = 0;
    while (dx < size.width) {
      canvas.drawLine(Offset(dx, targetY), Offset(dx + 8, targetY), dashPaint);
      dx += 14;
    }

    final linePaint = Paint()
      ..color = AppColors.cream
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = xOf(i);
      final y = yOf(data[i]['consumed'] as int);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = xOf(i - 1);
        final prevY = yOf(data[i - 1]['consumed'] as int);
        final cpX   = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = AppColors.cream;
    for (int i = 0; i < data.length; i++) {
      if (i % 3 == 0 || i == data.length - 1) {
        canvas.drawCircle(Offset(xOf(i), yOf(data[i]['consumed'] as int)), 3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_CalorieChartPainter old) => false;
}

class _LegendLinePainter extends CustomPainter {
  final Color color;
  final bool dashed;

  _LegendLinePainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (dashed) {
      canvas.drawLine(const Offset(0, 1), const Offset(6, 1), paint);
      canvas.drawLine(const Offset(10, 1), const Offset(16, 1), paint);
    } else {
      canvas.drawLine(const Offset(0, 1), const Offset(20, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _NewGoalSheet extends StatefulWidget {
  final List<String> goalTypes;
  final Function(Goal) onSubmit;
  const _NewGoalSheet({required this.goalTypes, required this.onSubmit});

  @override
  State<_NewGoalSheet> createState() => _NewGoalSheetState();
}

class _NewGoalSheetState extends State<_NewGoalSheet> {
  String _selectedType    = 'Manage weight';
  final _targetController = TextEditingController();
  final _rateController   = TextEditingController(text: '0.5');

  void _submit() {
    final target = double.tryParse(_targetController.text);
    final rate   = double.tryParse(_rateController.text);
    widget.onSubmit(Goal(
      type: _selectedType,
      targetWeight: target ?? 0,
      startingWeight: 68,
      startedAt: DateTime.now(),
      weeklyRate: rate,
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppGradient.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.blush, width: 0.3)),
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
              Text('Let\'s set\nyour goal', style: AppTextStyles.titleLarge.copyWith(fontSize: 34)),
              const SizedBox(height: 20),
              Text('GOAL TYPE', style: AppTextStyles.caption.copyWith(letterSpacing: 0.14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: widget.goalTypes.map((t) {
                  final sel = _selectedType == t;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.cream : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? AppColors.cream : AppColors.blush.withOpacity(0.3)),
                      ),
                      child: Text(t, style: AppTextStyles.label.copyWith(
                        fontSize: 12,
                        color: sel ? AppColors.darkBrown : AppColors.blush,
                        fontWeight: FontWeight.w500,
                      )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('TARGET WEIGHT (OPTIONAL)', style: AppTextStyles.caption.copyWith(letterSpacing: 0.14)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _targetController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTextStyles.inputValue.copyWith(color: AppColors.darkBrown, fontSize: 32),
                        decoration: InputDecoration(
                          hintText: '—',
                          hintStyle: AppTextStyles.inputValue.copyWith(color: AppColors.blush.withOpacity(0.4), fontSize: 32),
                          border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Text('kg', style: AppTextStyles.label.copyWith(color: AppColors.sienna, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('WEEKLY RATE (OPTIONAL)', style: AppTextStyles.caption.copyWith(letterSpacing: 0.14)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTextStyles.inputValue.copyWith(color: AppColors.darkBrown, fontSize: 32),
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      ),
                    ),
                    Text('kg / week', style: AppTextStyles.label.copyWith(color: AppColors.sienna, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('This informs your calorie target — not a deadline.', style: AppTextStyles.caption.copyWith(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.blush.withOpacity(0.6))),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _submit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
                  child: Text('Set goal', textAlign: TextAlign.center, style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightLogSheet extends StatefulWidget {
  final Function(WeightEntry) onAdd;
  const _WeightLogSheet({required this.onAdd});

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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppGradient.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.blush, width: 0.3)),
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
            Text('Log your\nweight', style: AppTextStyles.titleLarge.copyWith(fontSize: 34)),
            const SizedBox(height: 4),
            Text('Whenever feels right — no pressure to do this daily.', style: AppTextStyles.body.copyWith(fontSize: 13, fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: AppTextStyles.inputValue.copyWith(fontSize: 48, color: AppColors.darkBrown),
                      decoration: InputDecoration(
                        hintText: '0.0',
                        hintStyle: AppTextStyles.inputValue.copyWith(fontSize: 48, color: AppColors.blush.withOpacity(0.4)),
                        border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Text('kg', style: AppTextStyles.label.copyWith(color: AppColors.sienna, fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
                child: Text('Save', textAlign: TextAlign.center, style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
