import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../utils/theme.dart';
import '../main_shell.dart';
import 'register_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading     = false;
  bool _obscure     = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
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
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':   return 'No account found with that email.';
      case 'wrong-password':   return 'Incorrect password. Please try again.';
      case 'invalid-email':    return 'Please enter a valid email address.';
      case 'user-disabled':    return 'This account has been disabled.';
      case 'too-many-requests': return 'Too many attempts. Please try again later.';
      default: return 'Something went wrong. Please try again.';
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
                Text('elaarra', style: AppTextStyles.brandMark),
                const SizedBox(height: 32),
                Text(
                  'Welcome\nback',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to sync your data across devices.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 36),

                // Email field
                _buildInputField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'your@email.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),

                // Password field
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

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _sendPasswordReset,
                    child: Text(
                      'Forgot password?',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.blush,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),

                // Error message
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
                const SizedBox(height: 20),

                // Sign in button
                _buildPrimaryButton(
                  label: 'Sign in',
                  onTap: _signInWithEmail,
                  loading: _loading,
                ),
                const SizedBox(height: 16),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.blush.withOpacity(0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    ),
                    Expanded(child: Divider(color: AppColors.blush.withOpacity(0.3))),
                  ],
                ),
                const SizedBox(height: 16),

                // Google sign in
                _buildSocialButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                  onTap: _signInWithGoogle,
                ),
                const SizedBox(height: 10),

                // Apple sign in
                _buildSocialButton(
                  label: 'Continue with Apple',
                  icon: Icons.apple,
                  onTap: () {
                    // TODO: implement Apple sign in
                    setState(() => _error = 'Apple sign in coming soon.');
                  },
                ),
                const SizedBox(height: 32),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: AppTextStyles.caption.copyWith(fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: Text(
                        'Create one',
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
            content: Text(
              'Password reset email sent.',
              style: AppTextStyles.label.copyWith(color: AppColors.cream, fontSize: 13),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Could not send reset email. Check the address and try again.');
    }
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
            fontSize: 10, color: AppColors.midBrown,
          )),
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

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(14),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.darkBrown, strokeWidth: 2,
                  ),
                ),
              )
            : Text(label, textAlign: TextAlign.center, style: AppTextStyles.button),
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
