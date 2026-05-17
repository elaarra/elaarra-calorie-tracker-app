import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../utils/theme.dart';
import '../../services/database_service.dart';
import '../main_shell.dart';
import '../onboarding/onboarding_screen.dart';
import 'register_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading  = false;
  bool _obscure  = true;
  bool _showSignIn = false; // Start with the welcome view
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _signInWithEmail() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _navigateAfterAuth();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e.code));
    } catch (e) {
      if (mounted) setState(() => _error = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      await _navigateAfterAuth();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e.code));
    } catch (e) {
      if (mounted) setState(() => _error = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email above first.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.midBrown,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text('Password reset email sent.',
              style: AppTextStyles.label.copyWith(color: AppColors.cream, fontSize: 13)),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error: ${e.toString()}');
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':    return 'No account found with that email.';
      case 'wrong-password':    return 'Incorrect password. Please try again.';
      case 'invalid-email':     return 'Please enter a valid email address.';
      case 'invalid-credential': return 'Incorrect email or password. Please try again.';
      case 'user-disabled':     return 'This account has been disabled.';
      case 'too-many-requests': return 'Too many attempts. Please try again later.';
      default: return 'Sign in failed ($code). Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradient.background),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showSignIn ? _buildSignInView() : _buildWelcomeView(),
          ),
        ),
      ),
    );
  }

  // ── Welcome view ──────────────────────────────────────────
  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      key: const ValueKey('welcome'),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Image.asset('assets/images/logo_cream_alpha.png', height: 48),
          const SizedBox(height: 48),
          Text(
            'Hey, you.',
            style: AppTextStyles.titleLarge.copyWith(fontSize: 52),
          ),
          const SizedBox(height: 10),
          Text(
            'Your personal nutrition companion.\nLet\'s get started.',
            style: AppTextStyles.body.copyWith(fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 48),

          // Create account — primary, prominent
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Create an account',
                textAlign: TextAlign.center,
                style: AppTextStyles.button.copyWith(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sign in — secondary
          GestureDetector(
            onTap: () => setState(() => _showSignIn = true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.blush.withOpacity(0.3)),
              ),
              child: Text(
                'I already have an account',
                textAlign: TextAlign.center,
                style: AppTextStyles.button.copyWith(color: AppColors.cream),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Google
          _buildSocialButton(
            label: 'Continue with Google',
            icon: Icons.g_mobiledata_rounded,
            onTap: _signInWithGoogle,
          ),
          const SizedBox(height: 40),

          Text(
            'By continuing you agree to our Terms & Conditions and Privacy Policy.',
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.blush.withOpacity(0.6),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sign in view ──────────────────────────────────────────
  Widget _buildSignInView() {
    return SingleChildScrollView(
      key: const ValueKey('signin'),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          GestureDetector(
            onTap: () => setState(() { _showSignIn = false; _error = null; }),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.blush.withOpacity(0.3)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.cream, size: 16),
            ),
          ),
          const SizedBox(height: 32),
          Image.asset('assets/images/logo_cream_alpha.png', height: 48),
          const SizedBox(height: 24),
          Text(
            'Welcome\nback.',
            style: AppTextStyles.titleLarge.copyWith(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to sync your data across devices.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 32),

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
            obscure: _obscure,
            suffix: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.sienna, size: 18,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _sendPasswordReset,
              child: Text('Forgot password?',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.blush, fontSize: 11)),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.4)),
              ),
              child: Text(_error!,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.cream, fontSize: 13,
                  fontWeight: FontWeight.w400, height: 1.5)),
            ),
          ],
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _loading ? null : _signInWithEmail,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _loading
                  ? const Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.darkBrown, strokeWidth: 2)))
                  : Text('Sign in', textAlign: TextAlign.center,
                      style: AppTextStyles.button),
            ),
          ),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(child: Divider(color: AppColors.blush.withOpacity(0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: AppTextStyles.caption.copyWith(fontSize: 11)),
            ),
            Expanded(child: Divider(color: AppColors.blush.withOpacity(0.3))),
          ]),
          const SizedBox(height: 16),

          _buildSocialButton(
            label: 'Continue with Google',
            icon: Icons.g_mobiledata_rounded,
            onTap: _signInWithGoogle,
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Don\'t have an account? ',
                style: AppTextStyles.caption.copyWith(fontSize: 12)),
              GestureDetector(
                onTap: () {
                  setState(() => _showSignIn = false);
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: Text('Create one',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12, color: AppColors.cream,
                    fontWeight: FontWeight.w500)),
              ),
            ],
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
          Text(label, style: AppTextStyles.label.copyWith(
            fontSize: 10, color: AppColors.midBrown)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscure,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.darkBrown, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AppTextStyles.label.copyWith(
                      color: AppColors.blush.withOpacity(0.5), fontSize: 14),
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

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.blush.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.cream, size: 20),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.button.copyWith(color: AppColors.cream)),
          ],
        ),
      ),
    );
  }
}
