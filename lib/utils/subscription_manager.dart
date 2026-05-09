import 'package:flutter/material.dart';
import '../screens/paywall/paywall_screen.dart';
import '../utils/theme.dart';

// Wraps any premium feature — shows paywall if not premium
class PremiumGate extends StatelessWidget {
  final bool isPremium;
  final Widget child;
  final String featureName;

  const PremiumGate({
    Key? key,
    required this.isPremium,
    required this.child,
    required this.featureName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isPremium) return child;
    return _LockedFeature(featureName: featureName);
  }
}

class _LockedFeature extends StatelessWidget {
  final String featureName;

  const _LockedFeature({required this.featureName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.background),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(color: AppColors.blush.withOpacity(0.3)),
                ),
                child: const Center(
                  child: Icon(Icons.auto_awesome, color: AppColors.blush, size: 28),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'elaarra premium',
                style: AppTextStyles.titleLarge.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$featureName is a premium feature. Upgrade to unlock it.',
                style: AppTextStyles.body.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  isDismissible: false,
                  builder: (ctx) => DraggableScrollableSheet(
                    initialChildSize: 0.92,
                    minChildSize: 0.92,
                    maxChildSize: 0.92,
                    builder: (_, __) => PaywallScreen(
                      onDismiss: () => Navigator.pop(ctx),
                    ),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'See premium plans',
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
