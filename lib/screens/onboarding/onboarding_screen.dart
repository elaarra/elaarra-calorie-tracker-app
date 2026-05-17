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

  final _heightController = TextEditingController(text: '165');
  final _weightController = TextEditingController(text: '62');
  final _ageController    = TextEditingController(text: '28');
  final _nameController   = TextEditingController();
  String _gender          = 'female';
  String _selectedGoal    = 'Manage weight';
  String _manageDirection = 'lose'; // 'lose' or 'gain' — only used when goal is Manage weight
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

  int get _goalAdjustment {
    if (_selectedGoal == 'Manage weight') {
      return _manageDirection == 'lose' ? -500 : 300;
    }
    if (_selectedGoal == 'Gain muscle') return 300;
    return 0; // Maintain weight, Improve nutrition
  }

  int get _dailyCalories {
    final h = double.tryParse(_heightController.text) ?? 165;
    final w = double.tryParse(_weightController.text) ?? 62;
    final a = int.tryParse(_ageController.text) ?? 28;
    final double bmr = _gender == 'female'
        ? 447.593 + (9.247 * w) + (3.098 * h) - (4.330 * a)
        : 88.362 + (13.397 * w) + (4.799 * h) - (5.677 * a);
    final tdee = bmr * (_activityMultipliers[_activityLevel] ?? 1.375);
    return (tdee + _goalAdjustment).round();
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

  int get _protein => ((_dailyCalories * 0.30) / 4).round();
  int get _carbs   => ((_dailyCalories * 0.40) / 4).round();
  int get _fat     => ((_dailyCalories * 0.30) / 9).round();

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
          _buildTextInput('Your name', _nameController, hint: 'e.g. Ella'),
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
                      color: selected ? AppColors.darkBrown : AppColors.cream,
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
          _buildInputRow('Height', _heightController, 'cm'),
          _buildInputRow('Weight', _weightController, 'kg'),
          _buildInputRow('Age', _ageController, 'yrs'),
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
          // Sub-option for Manage weight
          if (_selectedGoal == 'Manage weight') ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                'I want to...',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10, color: AppColors.midBrown),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _manageDirection = 'lose'),
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
                      child: Text(
                        'Lose weight',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 11,
                          color: _manageDirection == 'lose'
                              ? AppColors.cream
                              : AppColors.midBrown,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _manageDirection = 'gain'),
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
                      child: Text(
                        'Gain weight',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 11,
                          color: _manageDirection == 'gain'
                              ? AppColors.cream
                              : AppColors.midBrown,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          // Medical disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.blush.withOpacity(0.2)),
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
        ? '${deficit} kcal below your maintenance'
        : deficit < 0
            ? '${deficit.abs()} kcal above your maintenance'
            : 'At your maintenance level';

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
                  style: AppTextStyles.caption.copyWith(letterSpacing: 0.14),
                ),
                const SizedBox(height: 6),
                Text(
                  _dailyCalories.toString(),
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 48),
                ),
                Text('kcal per day', style: AppTextStyles.caption),
                const SizedBox(height: 8),
                Text(
                  deficitLabel,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.blush.withOpacity(0.7),
                  ),
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
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.blush.withOpacity(0.2)),
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
          Text(label, style: AppTextStyles.label),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            style: AppTextStyles.inputValue,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.label.copyWith(color: AppColors.blush),
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
          Text(unit,
            style: AppTextStyles.label.copyWith(color: AppColors.sienna)),
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
            Text(value,
              style: AppTextStyles.inputValue.copyWith(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
