import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  // User inputs
  final _heightController = TextEditingController(text: '165');
  final _weightController = TextEditingController(text: '62');
  final _ageController    = TextEditingController(text: '28');
  String _gender          = 'female';
  String _selectedGoal    = 'Lose weight';
  String _activityLevel   = 'Lightly active';

  final List<String> _goals = [
    'Lose weight',
    'Build muscle',
    'Maintain weight',
    'Improve health',
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

  final Map<String, int> _goalAdjustments = {
    'Lose weight': -500,
    'Build muscle': 300,
    'Maintain weight': 0,
    'Improve health': 0,
  };

  // Calculates daily calorie target using Harris-Benedict
  int get _dailyCalories {
    final h = double.tryParse(_heightController.text) ?? 165;
    final w = double.tryParse(_weightController.text) ?? 62;
    final a = int.tryParse(_ageController.text) ?? 28;
    final double bmr = _gender == 'female'
        ? 447.593 + (9.247 * w) + (3.098 * h) - (4.330 * a)
        : 88.362 + (13.397 * w) + (4.799 * h) - (5.677 * a);
    final tdee = bmr * (_activityMultipliers[_activityLevel] ?? 1.375);
    return (tdee + (_goalAdjustments[_selectedGoal] ?? 0)).round();
  }

  int get _protein => ((_dailyCalories * 0.30) / 4).round();
  int get _carbs   => ((_dailyCalories * 0.40) / 4).round();
  int get _fat     => ((_dailyCalories * 0.30) / 9).round();

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      // TODO: save data and navigate to dashboard
      Navigator.of(context).pushReplacementNamed('/dashboard');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Text('elaarra', style: AppTextStyles.brandMark),
          const SizedBox(height: 16),
          // Progress bar
          Row(
            children: List.generate(_totalSteps, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 4 : 0),
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
            style: AppTextStyles.caption.copyWith(
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStatsStep();
      case 1: return _buildGoalStep();
      case 2: return _buildActivityStep();
      case 3: return _buildResultStep();
      default: return _buildStatsStep();
    }
  }

  // ── Step 1: Stats ──────────────────────────────────────────
  Widget _buildStatsStep() {
    return _buildStepWrapper(
      key: const ValueKey('stats'),
      title: "Let's get\nto know you",
      subtitle: 'Your stats shape everything.',
      child: Column(
        children: [
          // Gender selector
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
                      color: selected ? AppColors.darkBrown : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppColors.darkBrown : AppColors.blush,
                      ),
                    ),
                    child: Text(
                      g == 'female' ? 'Female' : 'Male',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.label.copyWith(
                        color: selected ? AppColors.cream : AppColors.midBrown,
                        fontFamily: 'NueveMontreal',
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
          _buildInputRow('Height', _heightController, 'cm'),
          _buildInputRow('Weight', _weightController, 'kg'),
          _buildInputRow('Age', _ageController, 'yrs'),
        ],
      ),
    );
  }

  // ── Step 2: Goal ───────────────────────────────────────────
  Widget _buildGoalStep() {
    return _buildStepWrapper(
      key: const ValueKey('goal'),
      title: "What's your\ngoal?",
      subtitle: "We'll personalise your daily target around this.",
      child: Column(
        children: _goals.map((g) => _buildChoiceChip(
          label: g,
          selected: _selectedGoal == g,
          onTap: () => setState(() => _selectedGoal = g),
        )).toList(),
      ),
    );
  }

  // ── Step 3: Activity ───────────────────────────────────────
  Widget _buildActivityStep() {
    return _buildStepWrapper(
      key: const ValueKey('activity'),
      title: 'How active\nare you?',
      subtitle: 'This refines your calorie calculation.',
      child: Column(
        children: _activityLevels.map((a) => _buildChoiceChip(
          label: a,
          selected: _activityLevel == a,
          onTap: () => setState(() => _activityLevel = a),
        )).toList(),
      ),
    );
  }

  // ── Step 4: Results ────────────────────────────────────────
  Widget _buildResultStep() {
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
                Text(
                  'DAILY CALORIES',
                  style: AppTextStyles.caption.copyWith(
                    letterSpacing: 0.14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _dailyCalories.toString(),
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 48),
                ),
                Text(
                  'kcal per day',
                  style: AppTextStyles.caption,
                ),
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
        ],
      ),
    );
  }

  // ── Shared layout wrapper ──────────────────────────────────
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
          // White card containing inputs/choices
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(14),
            child: child,
          ),
          const SizedBox(height: 16),
          // Navigation buttons
          Row(
            children: [
              if (_currentStep > 0) ...[
                GestureDetector(
                  onTap: _back,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Back',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.cream,
                      ),
                    ),
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

  Widget _buildInputRow(
    String label,
    TextEditingController controller,
    String unit,
  ) {
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
                Text(label, style: AppTextStyles.label),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTextStyles.inputValue,
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
          Text(unit, style: AppTextStyles.label.copyWith(color: AppColors.sienna)),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.darkBrown : AppColors.cream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.darkBrown : AppColors.blush,
          ),
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
            Text(label, style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.inputValue.copyWith(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
