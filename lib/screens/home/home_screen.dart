import 'package:provider/provider.dart';
import '../../state/app_state.dart';import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Temporary hardcoded data — replace with real data later ──
  final String _userName    = 'Ella';
  final int _dailyTarget    = 1650;
  int _caloriesConsumed     = 1240;

  final List<Map<String, dynamic>> _meals = [
    {'name': 'Porridge with berries', 'type': 'Breakfast', 'time': '08:30', 'kcal': 320},
    {'name': 'Grilled chicken salad', 'type': 'Lunch',     'time': '13:15', 'kcal': 480},
    {'name': 'Greek yoghurt',         'type': 'Snack',     'time': '16:00', 'kcal': 140},
  ];

  final int _streakDays = 7;

  // ── Macros (hardcoded for now) ────────────────────────────
  final int _proteinConsumed = 68;
  final int _proteinTarget   = 124;
  final int _carbsConsumed   = 112;
  final int _carbsTarget     = 165;
  final int _fatConsumed     = 38;
  final int _fatTarget       = 55;

  // ── Computed values ───────────────────────────────────────
  int get _remaining => (_dailyTarget - _caloriesConsumed).clamp(0, _dailyTarget);
  double get _progress => (_caloriesConsumed / _dailyTarget).clamp(0.0, 1.0);
  int get _percentage => (_progress * 100).round();
  bool get _isOver => _caloriesConsumed > _dailyTarget;

  String get _encouragement {
    if (_isOver) {
      return 'Every day is a fresh start — tomorrow is yours to own.';
    } else if (_percentage >= 90) {
      return 'Almost there. You\'ve been intentional today — finish strong.';
    } else if (_percentage >= 60) {
      return 'You\'re right where you need to be. Stay the course.';
    } else {
      return 'A great start. Your consistency is building something real.';
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  // ── Quick add sheet ───────────────────────────────────────
  void _openQuickAdd() {
    final controller = TextEditingController();
    String selectedType = 'Snack';
    final types = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppGradient.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: AppColors.blush, width: 0.3),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.blush.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Quick add', style: AppTextStyles.titleLarge.copyWith(fontSize: 32)),
                const SizedBox(height: 4),
                Text('Log calories in a few taps.', style: AppTextStyles.body),
                const SizedBox(height: 20),

                // Meal type selector
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: types.map((t) {
                      final sel = selectedType == t;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedType = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.cream : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel ? AppColors.cream : AppColors.blush.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            t,
                            style: AppTextStyles.label.copyWith(
                              color: sel ? AppColors.darkBrown : AppColors.blush,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Calorie input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: AppTextStyles.inputValue.copyWith(
                            color: AppColors.darkBrown,
                            fontSize: 36,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: AppTextStyles.inputValue.copyWith(
                              color: AppColors.blush,
                              fontSize: 36,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Text(
                        'kcal',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.sienna,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Add button
                GestureDetector(
                  onTap: () {
                    final kcal = int.tryParse(controller.text) ?? 0;
                    if (kcal > 0) {
                      setState(() {
                        _caloriesConsumed += kcal;
                        _meals.add({
                          'name': 'Quick add',
                          'type': selectedType,
                          'time': TimeOfDay.now().format(context),
                          'kcal': kcal,
                        });
                      });
                    }
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Add to today',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.button.copyWith(fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildProgressRing(),
              const SizedBox(height: 10),
              _buildEncouragement(),
              const SizedBox(height: 10),
              _buildMacros(),
              const SizedBox(height: 16),
              _buildMealList(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_greeting, style: AppTextStyles.body),
            Text(
              _userName,
              style: AppTextStyles.titleLarge.copyWith(fontSize: 40),
            ),
          ],
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: AppColors.blush.withOpacity(0.4)),
          ),
          child: Center(
            child: Text(
              _userName[0].toUpperCase(),
              style: AppTextStyles.label.copyWith(
                color: AppColors.blush,
                fontSize: 16,
                fontFamily: 'CormorantGaramond',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Progress ring ─────────────────────────────────────────
  Widget _buildProgressRing() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(
            'TODAY\'S PROGRESS',
            style: AppTextStyles.caption.copyWith(letterSpacing: 0.14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(140, 140),
                  painter: _RingPainter(progress: _progress, isOver: _isOver),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _caloriesConsumed.toString(),
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 30),
                    ),
                    Text(
                      'of $_dailyTarget',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRingStat(_isOver ? 'over' : 'remaining', _isOver ? (_caloriesConsumed - _dailyTarget).toString() : _remaining.toString()),
              Container(width: 0.5, height: 28, color: AppColors.blush.withOpacity(0.3)),
              _buildRingStat('of goal', '$_percentage%'),
              Container(width: 0.5, height: 28, color: AppColors.blush.withOpacity(0.3)),
              _buildRingStat('day streak', _streakDays.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRingStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.titleLarge.copyWith(fontSize: 20)),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }

  // ── Encouragement message ─────────────────────────────────
  Widget _buildEncouragement() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blush.withOpacity(0.2)),
      ),
      child: Text(
        _encouragement,
        style: AppTextStyles.body.copyWith(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: AppColors.cream,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── Macros ────────────────────────────────────────────────
  Widget _buildMacros() {
    return Row(
      children: [
        _buildMacroCard('protein', _proteinConsumed, _proteinTarget),
        const SizedBox(width: 8),
        _buildMacroCard('carbs', _carbsConsumed, _carbsTarget),
        const SizedBox(width: 8),
        _buildMacroCard('fat', _fatConsumed, _fatTarget),
      ],
    );
  }

  Widget _buildMacroCard(String label, int consumed, int target) {
    final prog = (consumed / target).clamp(0.0, 1.0);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${consumed}g',
              style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
            ),
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: prog,
                minHeight: 3,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cream),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Meal list ─────────────────────────────────────────────
  Widget _buildMealList() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TODAY\'S MEALS',
              style: AppTextStyles.caption.copyWith(letterSpacing: 0.14),
            ),
            GestureDetector(
              onTap: _openQuickAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cream.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.blush.withOpacity(0.3)),
                ),
                child: Text(
                  '+ add',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.cream,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: _meals.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Nothing logged yet — add your first meal.',
                      style: AppTextStyles.body.copyWith(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: _meals.asMap().entries.map((entry) {
                    final i = entry.key;
                    final m = entry.value;
                    final isLast = i == _meals.length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m['name'],
                                      style: AppTextStyles.label.copyWith(
                                        color: AppColors.cream,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${m['type']} · ${m['time']}',
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${m['kcal']}',
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 0.5,
                            color: AppColors.blush.withOpacity(0.2),
                            indent: 16,
                            endIndent: 16,
                          ),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

// ── Ring painter ──────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final bool isOver;

  _RingPainter({required this.progress, required this.isOver});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 10;
    const strokeW = 10.0;
    const startAngle = -1.5708; // -90 degrees

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      0, 6.2832, false,
      Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      6.2832 * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = isOver ? AppColors.sienna : AppColors.cream
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.isOver != isOver;
}
