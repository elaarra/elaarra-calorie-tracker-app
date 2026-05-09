import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/theme.dart';
import '../../services/database_service.dart';
import '../main_shell.dart';
import '../onboarding/onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  bool _loading  = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterAuth() async {
    final onboardingDone =
        await DatabaseService.instance.isOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            onboardingDone ? const MainShell() : const OnboardingScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _register() async {
    setState(() => _error = null);

    if (_emailController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email.');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _error = 'Passwords don\'t match.');
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _navigateAfterAuth();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e.code));
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradient.background),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.blush.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.cream,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text('elaarra', style: AppTextStyles.brandMark),
                const SizedBox(height: 16),
                Text(
                  'Create your\naccount',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your data will sync across all your devices.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 36),
                _buildInputField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'your@email.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: '••••••••',
                  obscure: _obscure1,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure1 = !_obscure1),
                    child: Icon(
                      _obscure1
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.sienna,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _confirmController,
                  label: 'Confirm password',
                  hint: '••••••••',
                  obscure: _obscure2,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure2 = !_obscure2),
                    child: Icon(
                      _obscure2
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.sienna,
                      size: 18,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error, fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _loading ? null : _register,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _loading
                        ? const Center(
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.darkBrown, strokeWidth: 2,
                              ),
                            ),
                          )
                        : Text(
                            'Create account',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.button,
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTextStyles.caption.copyWith(fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Sign in',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12,
                          color: AppColors.cream,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 10, color: AppColors.midBrown,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscure,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.darkBrown, fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AppTextStyles.label.copyWith(
                      color: AppColors.blush.withOpacity(0.5), fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 6),
                  ),
                ),
              ),
              if (suffix != null) suffix,
            ],
          ),
        ],
      ),
    );
  }
}
