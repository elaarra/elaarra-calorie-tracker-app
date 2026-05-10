import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../state/app_state.dart';
import '../log/log_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _proteinConsumed = 68;
  final int _proteinTarget   = 124;
  final int _carbsConsumed   = 112;
  final int _carbsTarget     = 165;
  final int _fatConsumed     = 38;
  final int _fatTarget       = 55;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  void _openQuickAdd() {
    final state = context.read<AppState>();
    final controller = TextEditingController();
    String selectedType = 'Snack';
    final types = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppGradient.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppColors.blush, width: 0.3)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
                Text('Quick add', style: AppTextStyles.titleLarge.copyWith(fontSize: 32)),
                const SizedBox(height: 4),
                Text('Log calories in a few taps.', style: AppTextStyles.body),
                const SizedBox(height: 20),
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
                          child: Text(t, style: AppTextStyles.label.copyWith(
                            color: sel ? AppColors.darkBrown : AppColors.blush,
                            fontSize: 12, fontWeight: FontWeight.w500,
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
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
                            color: AppColors.darkBrown, fontSize: 36,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: AppTextStyles.inputValue.copyWith(
                              color: AppColors.blush, fontSize: 36,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Text('kcal', style: AppTextStyles.label.copyWith(
                        color: AppColors.sienna, fontSize: 16,
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    final kcal = int.tryParse(controller.text) ?? 0;
                    if (kcal > 0) {
                      state.addEntry(
                        DateTime.now(),
                        LogEntry(calories: kcal, label: selectedType, loggedAt: DateTime.now()),
                      );
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
                    child: Text('Add to today', textAlign: TextAlign.center,
                      style: AppTextStyles.button.copyWith(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h   = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.background),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(state),
                  const SizedBox(height: 20),
                  _buildProgressRing(state),
                  const SizedBox(height: 10),
                  _buildEncouragement(state),
                  const SizedBox(height: 10),
                  _buildMacros(),
                  const SizedBox(height: 16),
                  _buildMealList(state),
                ]),
              ),
            ),
            // Fill remaining space with gradient
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                decoration: const BoxDecoration(gradient: AppGradient.background),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_greeting, style: AppTextStyles.body),
            Text(state.userName, style: AppTextStyles.titleLarge.copyWith(fontSize: 40)),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: AppColors.blush.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                state.userName.isNotEmpty ? state.userName[0].toUpperCase() : 'E',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.blush, fontSize: 16,
                  fontFamily: 'CormorantGaramond', fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRing(AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text('TODAY\'S PROGRESS', style: AppTextStyles.caption.copyWith(letterSpacing: 0.14)),
          const SizedBox(height: 16),
          SizedBox(
            width: 140, height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(140, 140),
                  painter: _RingPainter(
                    progress: state.todayProgress,
                    isOver: state.isOverToday,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.todayConsumed.toString(),
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 30)),
                    Text('of ${state.dailyTarget}', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRingStat(
                state.isOverToday ? 'over' : 'remaining',
                state.isOverToday
                    ? (state.todayConsumed - state.dailyTarget).toString()
                    : state.todayRemaining.toString(),
              ),
              Container(width: 0.5, height: 28, color: AppColors.blush.withOpacity(0.3)),
              _buildRingStat('of goal', '${(state.todayProgress * 100).round()}%'),
              Container(width: 0.5, height: 28, color: AppColors.blush.withOpacity(0.3)),
              _buildRingStat('day streak', state.streakDays.toString()),
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

  Widget _buildEncouragement(AppState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blush.withOpacity(0.2)),
      ),
      child: Text(
        state.encouragement,
        style: AppTextStyles.body.copyWith(
          fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.cream,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

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
            Text('${consumed}g', style: AppTextStyles.titleLarge.copyWith(fontSize: 20)),
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: prog, minHeight: 3,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cream),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealList(AppState state) {
    final meals = state.todayEntries;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TODAY\'S MEALS', style: AppTextStyles.caption.copyWith(letterSpacing: 0.14)),
            GestureDetector(
              onTap: _openQuickAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cream.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.blush.withOpacity(0.3)),
                ),
                child: Text('+ add', style: AppTextStyles.caption.copyWith(
                  color: AppColors.cream, fontSize: 11,
                )),
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
          child: meals.isEmpty
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
                  children: meals.asMap().entries.map((entry) {
                    final i = entry.key;
                    final m = entry.value;
                    final isLast = i == meals.length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name ?? 'Entry',
                                      style: AppTextStyles.label.copyWith(
                                        color: AppColors.cream, fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                      )),
                                    const SizedBox(height: 2),
                                    Text('${m.label ?? 'No label'} · ${_formatTime(m.loggedAt)}',
                                      style: AppTextStyles.caption.copyWith(fontSize: 10)),
                                  ],
                                ),
                              ),
                              Text('${m.calories}',
                                style: AppTextStyles.titleLarge.copyWith(fontSize: 18)),
                            ],
                          ),
                        ),
                        if (!isLast)
                          Divider(height: 0.5, color: AppColors.blush.withOpacity(0.2),
                            indent: 16, endIndent: 16),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

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
    const startAngle = -1.5708;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      0, 6.2832, false,
      Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

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
