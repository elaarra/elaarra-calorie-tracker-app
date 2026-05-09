import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../state/app_state.dart';
import '../auth/auth_screen.dart';
import '../paywall/paywall_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  String _activityLevel = 'Lightly active';
  String _goalType      = 'Manage weight';
  bool _edited          = false;

  final List<String> _activityLevels = [
    'Mostly sedentary',
    'Lightly active',
    'Moderately active',
    'Very active',
  ];

  final List<String> _goalTypes = [
    'Manage weight',
    'Build muscle',
    'Maintain lifestyle',
  ];

  @override
  void initState() {
    super.initState();
    final state       = context.read<AppState>();
    _nameController   = TextEditingController(text: state.userName);
    _targetController = TextEditingController(text: state.dailyTarget.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final state  = context.read<AppState>();
    final name   = _nameController.text.trim().isEmpty
        ? state.userName
        : _nameController.text.trim();
    final target = int.tryParse(_targetController.text) ?? state.dailyTarget;
    await state.updateUserName(name);
    await state.updateDailyTarget(target);
    setState(() => _edited = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.midBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Changes saved.',
            style: AppTextStyles.label.copyWith(color: AppColors.cream, fontSize: 13),
          ),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showModalBottomSheet<bool>(
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
            const SizedBox(height: 24),
            Text('Sign out?', style: AppTextStyles.titleLarge.copyWith(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'Your data is saved and will be here when you come back.',
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(ctx, true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('Yes, sign out', textAlign: TextAlign.center,
                  style: AppTextStyles.button),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(ctx, false),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('Cancel', textAlign: TextAlign.center,
                  style: AppTextStyles.button.copyWith(color: AppColors.cream)),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  void _openPaywall() {
    showModalBottomSheet(
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
    );
  }

  void _openNewGoalOptions() {
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
            Text('Start a new goal',
              style: AppTextStyles.titleLarge.copyWith(fontSize: 28)),
            const SizedBox(height: 6),
            Text('How would you like to proceed?', style: AppTextStyles.body),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _openUpdateGoal();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.blush.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_outlined,
                        color: AppColors.blush, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Update my goal', style: AppTextStyles.label.copyWith(
                            color: AppColors.cream, fontSize: 14,
                            fontWeight: FontWeight.w500,
                          )),
                          const SizedBox(height: 3),
                          Text('Recalculate your target — keep all your history.',
                            style: AppTextStyles.caption.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                      color: AppColors.blush, size: 13),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _confirmFreshStart();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.blush.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.refresh_outlined,
                        color: AppColors.error.withOpacity(0.8), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fresh start', style: AppTextStyles.label.copyWith(
                            color: AppColors.cream, fontSize: 14,
                            fontWeight: FontWeight.w500,
                          )),
                          const SizedBox(height: 3),
                          Text('Reset everything and start from scratch.',
                            style: AppTextStyles.caption.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                      color: AppColors.blush, size: 13),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openUpdateGoal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RecalculateSheet(
        onComplete: (int newTarget) async {
          final state = context.read<AppState>();
          await state.updateDailyTarget(newTarget);
          setState(() => _targetController.text = newTarget.toString());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.midBrown,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
                content: Text(
                  'Daily target updated to $newTarget kcal.',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.cream, fontSize: 13),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmFreshStart() {
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
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.warning_amber_outlined,
                color: AppColors.error.withOpacity(0.8), size: 24),
            ),
            const SizedBox(height: 16),
            Text('Are you sure?',
              style: AppTextStyles.titleLarge.copyWith(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'This will permanently erase all your logged meals, weight history, and goals. This cannot be undone.',
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () async {
                Navigator.pop(ctx);
                await _doFreshStart();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('Yes, erase everything',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.button.copyWith(color: AppColors.cream)),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('Cancel', textAlign: TextAlign.center,
                  style: AppTextStyles.button.copyWith(color: AppColors.cream)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doFreshStart() async {
    final state = context.read<AppState>();
    await state.resetAllData();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.midBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'All data cleared. Fresh start — you\'ve got this.',
            style: AppTextStyles.label.copyWith(color: AppColors.cream, fontSize: 13),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradient.background),
        child: SafeArea(
          child: Column(
            children: [
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
                    Text('Profile',
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 28)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                                border: Border.all(
                                  color: AppColors.blush.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  state.userName.isNotEmpty
                                      ? state.userName[0].toUpperCase()
                                      : 'E',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    fontSize: 32,
                                    fontFamily: 'CormorantGaramond',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(state.userName,
                              style: AppTextStyles.titleLarge.copyWith(
                                fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(
                              FirebaseAuth.instance.currentUser?.email ?? '',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Editable fields
                      Text('YOUR DETAILS',
                        style: AppTextStyles.caption.copyWith(
                          letterSpacing: 0.14)),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            _buildEditRow(
                              label: 'Name',
                              child: SizedBox(
                                width: 140,
                                child: TextField(
                                  controller: _nameController,
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.cream, fontSize: 14,
                                  ),
                                  textAlign: TextAlign.right,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: 'Your name',
                                    hintStyle: AppTextStyles.label.copyWith(
                                      color: AppColors.blush.withOpacity(0.4),
                                    ),
                                  ),
                                  onChanged: (_) =>
                                      setState(() => _edited = true),
                                ),
                              ),
                            ),
                            _buildDivider(),
                            _buildEditRow(
                              label: 'Daily target',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: TextField(
                                      controller: _targetController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      style: AppTextStyles.label.copyWith(
                                        color: AppColors.cream, fontSize: 14,
                                      ),
                                      textAlign: TextAlign.right,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (_) =>
                                          setState(() => _edited = true),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text('kcal',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 11)),
                                ],
                              ),
                            ),
                            _buildDivider(),
                            _buildPickerRow(
                              label: 'Activity level',
                              value: _activityLevel,
                              options: _activityLevels,
                              onChanged: (v) => setState(() {
                                _activityLevel = v;
                                _edited = true;
                              }),
                            ),
                            _buildDivider(),
                            _buildPickerRow(
                              label: 'Goal type',
                              value: _goalType,
                              options: _goalTypes,
                              onChanged: (v) => setState(() {
                                _goalType = v;
                                _edited = true;
                              }),
                            ),
                          ],
                        ),
                      ),

                      // Save button
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: _edited
                            ? Column(
                                children: [
                                  const SizedBox(height: 14),
                                  GestureDetector(
                                    onTap: _saveChanges,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                      decoration: BoxDecoration(
                                        color: AppColors.cream,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: Text('Save changes',
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.button),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 24),

                      // Goal section
                      Text('GOAL',
                        style: AppTextStyles.caption.copyWith(
                          letterSpacing: 0.14)),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _openNewGoalOptions,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.trending_up,
                                  color: AppColors.blush, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Start a new goal',
                                      style: AppTextStyles.label.copyWith(
                                        color: AppColors.cream, fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      )),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Update your target or start completely fresh.',
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 10)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                color: AppColors.blush, size: 13),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Account section
                      Text('ACCOUNT',
                        style: AppTextStyles.caption.copyWith(
                          letterSpacing: 0.14)),
                      const SizedBox(height: 10),

                      // Upgrade to premium (only if not premium)
                      if (!state.isPremium) ...[
                        GestureDetector(
                          onTap: _openPaywall,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.blush.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.blush.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.auto_awesome,
                                    color: AppColors.blush, size: 18),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Upgrade to premium',
                                        style: AppTextStyles.label.copyWith(
                                          color: AppColors.cream, fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        )),
                                      const SizedBox(height: 3),
                                      Text('Unlock AI scanning & more',
                                        style: AppTextStyles.caption.copyWith(
                                          fontSize: 10)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                  color: AppColors.blush, size: 13),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Premium badge (if premium)
                      if (state.isPremium) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.blush.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.blush.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.auto_awesome,
                                  color: AppColors.blush, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('elaarra premium',
                                      style: AppTextStyles.label.copyWith(
                                        color: AppColors.cream, fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      )),
                                    const SizedBox(height: 3),
                                    Text('Active — manage via the App Store',
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Sign out
                      GestureDetector(
                        onTap: _signOut,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.logout,
                                  color: AppColors.error.withOpacity(0.8),
                                  size: 18),
                              ),
                              const SizedBox(width: 14),
                              Text('Sign out',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.cream, fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                )),
                            ],
                          ),
                        ),
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

  Widget _buildEditRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(
            color: AppColors.blush, fontSize: 13,
          )),
          child,
        ],
      ),
    );
  }

  Widget _buildPickerRow({
    required String label,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(
            color: AppColors.blush, fontSize: 13,
          )),
          GestureDetector(
            onTap: () => _showPicker(label, value, options, onChanged),
            child: Row(
              children: [
                Text(value, style: AppTextStyles.label.copyWith(
                  color: AppColors.cream, fontSize: 13,
                )),
                const SizedBox(width: 6),
                const Icon(Icons.expand_more,
                  color: AppColors.blush, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(
    String title,
    String current,
    List<String> options,
    Function(String) onChanged,
  ) {
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
            Text(title,
              style: AppTextStyles.titleLarge.copyWith(fontSize: 24)),
            const SizedBox(height: 16),
            ...options.map((o) {
              final selected = o == current;
              return GestureDetector(
                onTap: () {
                  onChanged(o);
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.cream
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.cream
                          : AppColors.blush.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(o, style: AppTextStyles.label.copyWith(
                        color: selected
                            ? AppColors.darkBrown
                            : AppColors.cream,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w500
                            : FontWeight.w400,
                      )),
                      if (selected)
                        const Icon(Icons.check,
                          color: AppColors.darkBrown, size: 16),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 0.5,
      color: AppColors.blush.withOpacity(0.15),
      indent: 16,
      endIndent: 16,
    );
  }
}

// ── Recalculate sheet ─────────────────────────────────────────
class _RecalculateSheet extends StatefulWidget {
  final Function(int) onComplete;
  const _RecalculateSheet({required this.onComplete});

  @override
  State<_RecalculateSheet> createState() => _RecalculateSheetState();
}

class _RecalculateSheetState extends State<_RecalculateSheet> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController    = TextEditingController();
  String _gender        = 'female';
  String _activityLevel = 'Lightly active';
  String _goalType      = 'Manage weight';

  final Map<String, double> _activityMultipliers = {
    'Mostly sedentary': 1.2,
    'Lightly active': 1.375,
    'Moderately active': 1.55,
    'Very active': 1.725,
  };

  final Map<String, int> _goalAdjustments = {
    'Manage weight': -500,
    'Build muscle': 300,
    'Maintain lifestyle': 0,
  };

  final List<String> _activityLevels = [
    'Mostly sedentary',
    'Lightly active',
    'Moderately active',
    'Very active',
  ];

  final List<String> _goalTypes = [
    'Manage weight',
    'Build muscle',
    'Maintain lifestyle',
  ];

  int get _calculatedTarget {
    final h = double.tryParse(_heightController.text) ?? 165;
    final w = double.tryParse(_weightController.text) ?? 62;
    final a = int.tryParse(_ageController.text) ?? 28;
    final double bmr = _gender == 'female'
        ? 447.593 + (9.247 * w) + (3.098 * h) - (4.330 * a)
        : 88.362 + (13.397 * w) + (4.799 * h) - (5.677 * a);
    final tdee = bmr * (_activityMultipliers[_activityLevel] ?? 1.375);
    return (tdee + (_goalAdjustments[_goalType] ?? 0)).round();
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppGradient.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.blush, width: 0.3)),
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
              Text('Recalculate\nyour target',
                style: AppTextStyles.titleLarge.copyWith(fontSize: 30)),
              const SizedBox(height: 4),
              Text(
                'Update your details and we\'ll work out a new daily goal.',
                style: AppTextStyles.body),
              const SizedBox(height: 20),
              Row(
                children: ['female', 'male'].map((g) {
                  final sel = _gender == g;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = g),
                      child: Container(
                        margin: EdgeInsets.only(right: g == 'female' ? 6 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.cream
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? AppColors.cream
                                : AppColors.blush.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          g == 'female' ? 'Female' : 'Male',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.label.copyWith(
                            color: sel
                                ? AppColors.darkBrown
                                : AppColors.blush,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildInputRow('Height', _heightController, 'cm'),
                    const SizedBox(height: 8),
                    _buildInputRow('Weight', _weightController, 'kg'),
                    const SizedBox(height: 8),
                    _buildInputRow('Age', _ageController, 'yrs'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('ACTIVITY LEVEL',
                style: AppTextStyles.caption.copyWith(
                  letterSpacing: 0.14, color: AppColors.blush)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _activityLevels.map((a) {
                  final sel = _activityLevel == a;
                  return GestureDetector(
                    onTap: () => setState(() => _activityLevel = a),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
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
                      child: Text(a, style: AppTextStyles.label.copyWith(
                        fontSize: 11,
                        color: sel ? AppColors.darkBrown : AppColors.blush,
                        fontWeight: FontWeight.w500,
                      )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text('GOAL TYPE',
                style: AppTextStyles.caption.copyWith(
                  letterSpacing: 0.14, color: AppColors.blush)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _goalTypes.map((g) {
                  final sel = _goalType == g;
                  return GestureDetector(
                    onTap: () => setState(() => _goalType = g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
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
                      child: Text(g, style: AppTextStyles.label.copyWith(
                        fontSize: 11,
                        color: sel ? AppColors.darkBrown : AppColors.blush,
                        fontWeight: FontWeight.w500,
                      )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.blush.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('New daily target',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.blush)),
                    Text('$_calculatedTarget kcal',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontSize: 22)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  widget.onComplete(_calculatedTarget);
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('Update target',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow(
    String label,
    TextEditingController controller,
    String unit,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.label.copyWith(
                color: AppColors.midBrown, fontSize: 11,
              )),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.inputValue.copyWith(
                  color: AppColors.darkBrown, fontSize: 24,
                ),
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
        Text(unit, style: AppTextStyles.label.copyWith(
          color: AppColors.sienna)),
      ],
    );
  }
}
