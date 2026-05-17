import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../state/app_state.dart';
import '../main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  final _heightController      = TextEditingController();
  final _weightController      = TextEditingController();
  final _ageController         = TextEditingController();
  final _nameController        = TextEditingController();
  final _weightTargetController = TextEditingController();

  String _gender          = 'female';
  String _selectedGoal    = 'Manage weight';
  String _manageDirection = 'lose';
  String _activityLevel   = 'Lightly active';

  final List<String> _goals = [
    'Manage weight',
    'Maintain weight',
    'Improve nutrition',
    'Gain muscle',
  ];

  final List<String> _activityLevels = [
    'Mostly sedentary',
    'Lightly active',
    'Moderately active',
    'Very active',
  ];

  final Map<String, double> _activityMultipliers = {
    'Mostly sedentary': 1.2,
    'Lightly active': 1.375,
    'Moderately active': 1.55,
    'Very active': 1.725,
  };

  String get _activityDescription {
    switch (_activityLevel) {
      case 'Mostly sedentary':
        return 'Little or no exercise, desk job.';
      case 'Lightly active':
        return 'Light exercise 1-3 days/week.';
      case 'Moderately active':
        return 'Moderate exercise 3-5 days/week.';
      case 'Very active':
        return 'Hard exercise 6-7 days/week.';
      default:
        return '';
    }
  }

  int get _goalAdjustment {
    if (_selectedGoal == 'Manage weight') {
      return _manageDirection == 'lose' ? -500 : 300;
    }
    if (_selectedGoal == 'Gain muscle') return 300;
    return 0;
  }

  int get _tdee {
    final h = double.tryParse(_heightController.text) ?? 165;
    final w = double.tryParse(_weightController.text) ?? 62;
    final a = int.tryParse(_ageController.text) ?? 28;
    final double bmr = _gender == 'female'
        ? 447.593 + (9.247 * w) + (3.098 * h) - (4.330 * a)
        : 88.362 + (13.397 * w) + (4.799 * h) - (5.677 * a);
    return (bmr * (_activityMultipliers[_activityLevel] ?? 1.375)).round();
  }

  int get _dailyCalories => (_tdee + _goalAdjustment).round();
  int get _protein => ((_dailyCalories * 0.30) / 4).round();
  int get _carbs   => ((_dailyCalories * 0.40) / 4).round();
  int get _fat     => ((_dailyCalories * 0.30) / 9).round();

  // How long it will take to reach target at 500kcal deficit/surplus
  String get _timeEstimate {
    final targetKg = double.tryParse(_weightTargetController.text);
    final currentKg = double.tryParse(_weightController.text) ?? 62;
    if (targetKg == null) return '';
    final diff = (currentKg - targetKg).abs();
    if (diff == 0) return '';
    // 1kg of fat ≈ 7700 kcal, 500 kcal/day = ~1kg/2 weeks
    final weeks = (diff / 0.5).ceil();
    if (weeks < 4) return 'approx. $weeks weeks';
    final months = (weeks / 4.3).ceil();
    return 'approx. $months months';
  }

  bool get _isLowCalorieTarget {
    final minSafe = _gender == 'female' ? 1200 : 1500;
    return _dailyCalories < minSafe;
  }

  bool get _isUnrealisticTarget {
    final targetKg = double.tryParse(_weightTargetController.text);
    final currentKg = double.tryParse(_weightController.text) ?? 62;
    if (targetKg == null) return false;
    // Flag if target is less than 45kg or more than 50% away from current weight
    if (targetKg < 45) return true;
    final diff = (currentKg - targetKg).abs();
    if (diff > currentKg * 0.5) return true;
    return false;
  }

  Future<void> _next() async {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      final state = context.read<AppState>();
      final name  = _nameController.text.trim().isEmpty
          ? 'there'
          : _nameController.text.trim();
      await state.updateProfileFromOnboarding(
        name: name,
        target: _dailyCalories,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    }
  }

  void _back() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _nameController.dispose();
    _weightTargetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBrown,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradient.background),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/images/logo_cream_alpha.png', height: 48),
          const SizedBox(height: 16),
          Row(
            children: List.generate(_totalSteps, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: i < _totalSteps - 1 ? 4 : 0),
                  height: 3,
                  decoration: BoxDecoration(
                    color: i <= _currentStep
                        ? AppColors.cream
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: AppTextStyles.caption.copyWith(letterSpacing: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildNameStep();
      case 1: return _buildStatsStep();
      case 2: return _buildGoalStep();
      case 3: return _buildResultStep();
      default: return _buildNameStep();
    }
  }

  // ── Step 1: Name ───────────────────────────────────────────
  Widget _buildNameStep() {
    return _buildStepWrapper(
      key: const ValueKey('name'),
      title: 'What should\nwe call you?',
      subtitle: 'This is how elaarra will greet you each day.',
      child: Column(
        children: [
          _buildTextInput(
            'Your name',
            _nameController,
            hint: 'e.g. Ella',
            capitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }

  // ── Step 2: Stats ──────────────────────────────────────────
  Widget _buildStatsStep() {
    return _buildStepWrapper(
      key: const ValueKey('stats'),
      title: "Let's get\nto know you",
      subtitle: 'Your stats shape your daily target.',
      child: Column(
        children: [
          Row(
            children: ['female', 'male'].map((g) {
              final selected = _gender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = g),
                  child: Container(
                    margin: EdgeInsets.only(right: g == 'female' ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.darkBrown
                          : AppColors.cream,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.darkBrown
                            : AppColors.blush,
                      ),
                    ),
                    child: Text(
                      g == 'female' ? 'Female' : 'Male',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.label.copyWith(
                        color: selected
                            ? AppColors.cream
                            : AppColors.midBrown,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          _buildInputRow('Height', _heightController, 'cm',
            color: AppColors.darkBrown),
          _buildInputRow('Weight', _weightController, 'kg',
            color: AppColors.darkBrown),
          _buildInputRow('Age', _ageController, 'yrs',
            color: AppColors.darkBrown),
          const SizedBox(height: 8),
          // Activity level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activity level',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.midBrown, fontSize: 11)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _activityLevels.map((a) {
                    final sel = _activityLevel == a;
                    return GestureDetector(
                      onTap: () => setState(() => _activityLevel = a),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.darkBrown
                              : Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? AppColors.darkBrown
                                : AppColors.blush,
                          ),
                        ),
                        child: Text(a,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: sel
                                ? AppColors.cream
                                : AppColors.midBrown,
                            fontWeight: FontWeight.w500,
                          )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  _activityDescription,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.midBrown.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Goal ───────────────────────────────────────────
  Widget _buildGoalStep() {
    return _buildStepWrapper(
      key: const ValueKey('goal'),
      title: "What's your\ngoal?",
      subtitle: "We'll personalise your daily target around this.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._goals.map((g) => _buildChoiceChip(
            label: g,
            selected: _selectedGoal == g,
            onTap: () => setState(() => _selectedGoal = g),
          )),

          // Sub-options for Manage weight
          if (_selectedGoal == 'Manage weight') ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 6),
              child: Text('I want to...',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10, color: AppColors.midBrown)),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _manageDirection = 'lose'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _manageDirection == 'lose'
                            ? AppColors.darkBrown
                            : AppColors.cream,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _manageDirection == 'lose'
                              ? AppColors.darkBrown
                              : AppColors.blush,
                        ),
                      ),
                      child: Text('Lose weight',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 11,
                          color: _manageDirection == 'lose'
                              ? AppColors.cream
                              : AppColors.midBrown,
                          fontWeight: FontWeight.w500,
                        )),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _manageDirection = 'gain'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _manageDirection == 'gain'
                            ? AppColors.darkBrown
                            : AppColors.cream,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _manageDirection == 'gain'
                              ? AppColors.darkBrown
                              : AppColors.blush,
                        ),
                      ),
                      child: Text('Gain weight',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 11,
                          color: _manageDirection == 'gain'
                              ? AppColors.cream
                              : AppColors.midBrown,
                          fontWeight: FontWeight.w500,
                        )),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Target weight input
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target weight',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.midBrown, fontSize: 11)),
                        TextField(
                          controller: _weightTargetController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d*'))
                          ],
                          style: AppTextStyles.inputValue.copyWith(
                            color: AppColors.darkBrown, fontSize: 24),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: AppTextStyles.inputValue.copyWith(
                              color: AppColors.blush, fontSize: 24),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  Text('kg',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.sienna)),
                ],
              ),
            ),
            if (_isUnrealisticTarget) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Text(
                  'This target may not be realistic or safe. We recommend consulting your doctor before setting an extreme weight goal.',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.error.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
              ),
            ] else if (_timeEstimate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'At a safe rate, you could reach your goal in $_timeEstimate.',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: AppColors.blush.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ],
          ],
          const SizedBox(height: 10),
          // Medical disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.blush.withOpacity(0.2)),
            ),
            child: Text(
              'Always consult your doctor before making significant changes to your diet or exercise routine. elaarra is a wellness tool, not a medical service.',
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: AppColors.blush.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 4: Results ────────────────────────────────────────
  Widget _buildResultStep() {
    final deficit = _tdee - _dailyCalories;
    final deficitLabel = deficit > 0
        ? '$deficit kcal below your maintenance (${_tdee} kcal)'
        : deficit < 0
            ? '${deficit.abs()} kcal above your maintenance (${_tdee} kcal)'
            : 'At your maintenance level (${_tdee} kcal)';

    return _buildStepWrapper(
      key: const ValueKey('result'),
      title: 'Your daily\ntarget',
      subtitle: 'Based on your profile — here\'s your goal.',
      buttonLabel: 'Start tracking',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.darkBrown,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('DAILY CALORIES',
                  style: AppTextStyles.caption.copyWith(
                    letterSpacing: 0.14)),
                const SizedBox(height: 6),
                Text(_dailyCalories.toString(),
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 48)),
                Text('kcal per day',
                  style: AppTextStyles.caption),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(deficitLabel,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.blush.withOpacity(0.7),
                      height: 1.5,
                    )),
                ),
                if (_timeEstimate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Estimated time to goal: $_timeEstimate',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.blush.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMacroCard('Protein', '$_protein g'),
              const SizedBox(width: 8),
              _buildMacroCard('Carbs', '$_carbs g'),
              const SizedBox(width: 8),
              _buildMacroCard('Fat', '$_fat g'),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLowCalorieTarget) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3)),
              ),
              child: Text(
                'Your calculated target is below the recommended minimum for safe weight loss. We strongly recommend speaking with a doctor or dietitian before proceeding. elaarra supports your wellbeing — please be kind to yourself.',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: AppColors.error.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.blush.withOpacity(0.2)),
            ),
            child: Text(
              'These are estimates based on the Harris-Benedict equation. Individual needs vary. elaarra is not a substitute for professional medical or nutritional advice.',
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: AppColors.blush.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared wrapper ─────────────────────────────────────────
  Widget _buildStepWrapper({
    required Key key,
    required String title,
    required String subtitle,
    required Widget child,
    String buttonLabel = 'Continue',
  }) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTextStyles.body),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(14),
            child: child,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_currentStep > 0) ...[
                GestureDetector(
                  onTap: _back,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Back',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.cream)),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: _next,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      buttonLabel,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.button,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput(
    String label,
    TextEditingController controller, {
    String? hint,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(
            color: AppColors.midBrown, fontSize: 11)),
          TextField(
            controller: controller,
            textCapitalization: capitalization,
            style: AppTextStyles.label.copyWith(
              color: AppColors.darkBrown, fontSize: 18),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.label.copyWith(
                color: AppColors.blush),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(
    String label,
    TextEditingController controller,
    String unit, {
    Color color = AppColors.darkBrown,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.label.copyWith(
                  color: AppColors.midBrown, fontSize: 11)),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly],
                  style: AppTextStyles.inputValue.copyWith(
                    color: color, fontSize: 24),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          Text(unit,
            style: AppTextStyles.label.copyWith(
              color: AppColors.sienna)),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.darkBrown : AppColors.cream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.darkBrown : AppColors.blush),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            fontSize: 12,
            color: selected ? AppColors.cream : AppColors.midBrown,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMacroCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.label.copyWith(
              color: AppColors.midBrown, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value,
              style: AppTextStyles.inputValue.copyWith(
                color: AppColors.darkBrown, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
