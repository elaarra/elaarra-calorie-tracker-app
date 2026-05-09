import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../state/app_state.dart';

class PaywallScreen extends StatefulWidget {
  final bool fullScreen;
  final VoidCallback? onDismiss;

  const PaywallScreen({
    Key? key,
    this.fullScreen = false,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selectedPlan = 'annual';
  bool _showExitOffer  = false;

  void _handleNotNow() => setState(() => _showExitOffer = true);

  void _handleDismiss() {
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleSubscribe() async {
    // TODO: wire up real in-app purchase here
    final state = context.read<AppState>();
    await state.togglePremium();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.midBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Welcome to elaarra premium.',
            style: AppTextStyles.label.copyWith(color: AppColors.cream, fontSize: 13),
          ),
        ),
      );
      _handleDismiss();
    }
  }

  Future<void> _handleStartTrial() async {
    // TODO: wire up real trial purchase here
    final state = context.read<AppState>();
    await state.togglePremium();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.midBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Your 14-day free trial has started. Enjoy.',
            style: AppTextStyles.label.copyWith(color: AppColors.cream, fontSize: 13),
          ),
        ),
      );
      _handleDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fullScreen) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppGradient.background),
          child: SafeArea(child: _buildContent()),
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradient.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.blush, width: 0.3)),
      ),
      child: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showExitOffer ? _buildExitOffer() : _buildMainPaywall(),
    );
  }

  // ── Screen 1: Main paywall ────────────────────────────────
  Widget _buildMainPaywall() {
    return SingleChildScrollView(
      key: const ValueKey('main'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.fullScreen)
            Center(
              child: Container(
                width: 36, height: 3,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.blush.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

          // Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: AppColors.blush.withOpacity(0.4)),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome, color: AppColors.blush, size: 24),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Unlock elaarra\npremium',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Feature list
          _buildFeature(Icons.camera_alt_outlined, 'AI food & label scanning'),
          const SizedBox(height: 8),
          _buildFeature(Icons.trending_up, 'Multiple goals simultaneously'),
          const SizedBox(height: 8),
          _buildFeature(Icons.insights_outlined, 'Advanced analytics & insights'),
          const SizedBox(height: 20),

          // Annual plan (recommended)
          GestureDetector(
            onTap: () => setState(() => _selectedPlan = 'annual'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedPlan == 'annual'
                    ? Colors.white.withOpacity(0.95)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedPlan == 'annual'
                      ? Colors.transparent
                      : AppColors.blush.withOpacity(0.2),
                ),
              ),
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Annual',
                            style: AppTextStyles.label.copyWith(
                              color: _selectedPlan == 'annual'
                                  ? AppColors.darkBrown
                                  : AppColors.cream,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '£29.99 / year',
                            style: AppTextStyles.caption.copyWith(
                              color: _selectedPlan == 'annual'
                                  ? AppColors.midBrown
                                  : AppColors.blush,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.midBrown,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'SAVE 37%',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 8,
                                color: AppColors.cream,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _selectedPlan == 'annual'
                                  ? AppColors.midBrown
                                  : Colors.transparent,
                              border: Border.all(
                                color: _selectedPlan == 'annual'
                                    ? AppColors.midBrown
                                    : AppColors.blush.withOpacity(0.4),
                              ),
                            ),
                            child: _selectedPlan == 'annual'
                                ? const Icon(Icons.check,
                                    color: AppColors.cream, size: 12)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Monthly plan
          GestureDetector(
            onTap: () => setState(() => _selectedPlan = 'monthly'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedPlan == 'monthly'
                    ? Colors.white.withOpacity(0.95)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedPlan == 'monthly'
                      ? Colors.transparent
                      : AppColors.blush.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly',
                        style: AppTextStyles.label.copyWith(
                          color: _selectedPlan == 'monthly'
                              ? AppColors.darkBrown
                              : AppColors.cream,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '£3.99 / month',
                        style: AppTextStyles.caption.copyWith(
                          color: _selectedPlan == 'monthly'
                              ? AppColors.midBrown
                              : AppColors.blush,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedPlan == 'monthly'
                          ? AppColors.midBrown
                          : Colors.transparent,
                      border: Border.all(
                        color: _selectedPlan == 'monthly'
                            ? AppColors.midBrown
                            : AppColors.blush.withOpacity(0.4),
                      ),
                    ),
                    child: _selectedPlan == 'monthly'
                        ? const Icon(Icons.check,
                            color: AppColors.cream, size: 12)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // CTA
          GestureDetector(
            onTap: _handleSubscribe,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Get started',
                textAlign: TextAlign.center,
                style: AppTextStyles.button,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Small print — this is where the trial lives
          Text(
            '14 days on us, no charge until your trial ends · Cancel anytime',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.blush.withOpacity(0.7),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),

          // Not now
          Center(
            child: GestureDetector(
              onTap: _handleNotNow,
              child: Text(
                'Not now',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.blush.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Screen 2: Exit offer ──────────────────────────────────
  Widget _buildExitOffer() {
    return SingleChildScrollView(
      key: const ValueKey('exit'),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Before\nyou go...',
            style: AppTextStyles.titleLarge.copyWith(fontSize: 40),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'d love you to experience elaarra premium first — completely free.',
            style: AppTextStyles.body.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 28),

          // Trial offer card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.blush.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FREE FOR 14 DAYS',
                  style: AppTextStyles.caption.copyWith(
                    letterSpacing: 0.14,
                    color: AppColors.blush,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try elaarra premium free — no payment needed today.',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 12),
                _buildFeature(Icons.camera_alt_outlined, 'AI food & label scanning'),
                const SizedBox(height: 6),
                _buildFeature(Icons.trending_up, 'Multiple goals simultaneously'),
                const SizedBox(height: 6),
                _buildFeature(Icons.insights_outlined, 'Advanced analytics & insights'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Trial CTA
          GestureDetector(
            onTap: _handleStartTrial,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Start my free trial',
                textAlign: TextAlign.center,
                style: AppTextStyles.button,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'No payment needed · Cancel anytime before trial ends',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.blush.withOpacity(0.7),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),

          // Hard dismiss
          Center(
            child: GestureDetector(
              onTap: _handleDismiss,
              child: Text(
                'No thanks, I\'ll stay on the free plan',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.blush.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.blush, size: 16),
        const SizedBox(width: 10),
        Text(
          text,
          style: AppTextStyles.label.copyWith(
            color: AppColors.cream,
            fontSize: 12,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}
