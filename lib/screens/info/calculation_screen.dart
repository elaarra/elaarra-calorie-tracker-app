import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class CalculationScreen extends StatelessWidget {
  const CalculationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradient.background),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.blush.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                          color: AppColors.cream, size: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('How we calculate this',
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 22)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        title: 'Your daily calorie target',
                        body: 'Your target is calculated using the Harris-Benedict equation — one of the most widely used methods in nutrition science. It estimates how many calories your body burns each day based on your personal stats and activity level.',
                      ),
                      _buildSection(
                        title: 'Step 1 — Basal Metabolic Rate (BMR)',
                        body: 'BMR is the number of calories your body needs just to stay alive — breathing, circulation, cell production — even if you did nothing all day.\n\nFor women:\nBMR = 447.6 + (9.25 × weight kg) + (3.10 × height cm) − (4.33 × age)\n\nFor men:\nBMR = 88.36 + (13.40 × weight kg) + (4.80 × height cm) − (5.68 × age)',
                        isFormula: true,
                      ),
                      _buildSection(
                        title: 'Step 2 — Total Daily Energy Expenditure (TDEE)',
                        body: 'Your BMR is multiplied by an activity factor to account for how much you move:\n\n• Mostly sedentary — ×1.2\n• Lightly active — ×1.375\n• Moderately active — ×1.55\n• Very active — ×1.725\n\nThe result is your TDEE — the calories you need to maintain your current weight.',
                      ),
                      _buildSection(
                        title: 'Step 3 — Your goal adjustment',
                        body: 'Depending on your goal, we adjust your TDEE:\n\n• Lose weight — we subtract 500 kcal/day. At this rate, you\'d lose approximately 0.5kg per week, which is considered a safe and sustainable rate.\n\n• Gain weight — we add 300 kcal/day to support gradual, healthy weight gain.\n\n• Maintain or improve nutrition — your target stays at your TDEE.',
                      ),
                      _buildSection(
                        title: 'Why 500 kcal?',
                        body: '1kg of body fat contains approximately 7,700 kcal of energy. A daily deficit of 500 kcal over 7 days = 3,500 kcal = roughly 0.5kg of fat loss per week.\n\nThis is the rate most health professionals consider safe and sustainable for long-term results.',
                      ),
                      _buildSection(
                        title: 'Important — these are estimates',
                        body: 'The Harris-Benedict equation is a well-validated tool, but no formula can perfectly predict individual metabolism. Factors like sleep, stress, hormones, and medical conditions all affect how your body uses energy.\n\nUse your daily target as a guide, not a rule. If you consistently feel unwell, fatigued, or unwell at your target, please speak to a healthcare professional.\n\nelaarra is a wellness tool — not a medical service.',
                        isWarning: true,
                      ),
                      _buildSection(
                        title: 'Macronutrients',
                        body: 'elaarra estimates your macros using standard nutritional ratios:\n\n• Protein — 30% of daily calories ÷ 4 (protein has 4 kcal/g)\n• Carbohydrates — 40% of daily calories ÷ 4\n• Fat — 30% of daily calories ÷ 9 (fat has 9 kcal/g)\n\nThese ratios are a starting point. Your ideal macro split may vary based on your specific goals and health needs.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String body,
    bool isFormula = false,
    bool isWarning = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning
            ? AppColors.error.withOpacity(0.08)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning
              ? AppColors.error.withOpacity(0.2)
              : AppColors.blush.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: AppTextStyles.label.copyWith(
              color: isWarning
                  ? AppColors.error.withOpacity(0.9)
                  : AppColors.cream,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            )),
          const SizedBox(height: 8),
          Text(body,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              color: isWarning
                  ? AppColors.error.withOpacity(0.8)
                  : AppColors.blush,
              height: 1.7,
              fontFamily: isFormula ? 'monospace' : null,
            )),
        ],
      ),
    );
  }
}
