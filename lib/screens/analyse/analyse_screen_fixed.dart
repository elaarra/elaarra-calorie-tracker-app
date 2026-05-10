import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../state/app_state.dart';
import '../../services/gemini_service.dart';
import '../log/log_screen.dart';
import '../paywall/paywall_screen.dart';

class AnalyseScreen extends StatefulWidget {
  const AnalyseScreen({Key? key}) : super(key: key);

  @override
  State<AnalyseScreen> createState() => _AnalyseScreenState();
}

class _AnalyseScreenState extends State<AnalyseScreen> {
  // Screen state: 'split' | 'loading' | 'results' | 'error'
  String _screenState = 'split';
  String _mode        = '';
  File?  _imageFile;
  GeminiResult? _result;
  String? _errorMessage;

  late TextEditingController _nameController;
  late TextEditingController _kcalController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  @override
  void initState() {
    super.initState();
    _nameController    = TextEditingController();
    _kcalController    = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController   = TextEditingController();
    _fatController     = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _populateControllers(GeminiResult result) {
    _nameController.text    = result.foodName;
    _kcalController.text    = result.calories.toString();
    _proteinController.text = result.protein.toString();
    _carbsController.text   = result.carbs.toString();
    _fatController.text     = result.fat.toString();
  }

  Future<void> _selectMode(String mode) async {
    setState(() {
      _mode        = mode;
      _screenState = 'loading';
      _imageFile   = null;
      _result      = null;
      _errorMessage = null;
    });

    try {
      // Get image from camera
      final image = await GeminiService.instance.takePhoto();
      if (image == null) {
        // User cancelled camera
        setState(() => _screenState = 'split');
        return;
      }

      setState(() => _imageFile = image);

      // Call Gemini
      final result = mode == 'food'
          ? await GeminiService.instance.analyseFood(image)
          : await GeminiService.instance.scanLabel(image);

      if (result == null || result.calories == 0) {
        setState(() {
          _screenState  = 'error';
          _errorMessage = mode == 'food'
              ? 'We couldn\'t identify the food clearly. Try again with better lighting or a closer shot.'
              : 'We couldn\'t read the label clearly. Make sure the label is flat, well-lit and fills the frame.';
        });
        return;
      }

      _populateControllers(result);
      setState(() {
        _result      = result;
        _screenState = 'results';
      });
    } catch (e) {
      setState(() {
        _screenState  = 'error';
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  void _reset() {
    setState(() {
      _screenState  = 'split';
      _mode         = '';
      _imageFile    = null;
      _result       = null;
      _errorMessage = null;
    });
  }

  void _logMeal(BuildContext context) {
    final state = context.read<AppState>();
    final kcal  = int.tryParse(_kcalController.text) ?? 0;
    if (kcal > 0) {
      state.addEntry(
        DateTime.now(),
        LogEntry(
          calories: kcal,
          name: _nameController.text.isEmpty ? null : _nameController.text,
          label: 'Analyse',
          loggedAt: DateTime.now(),
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.midBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          '${_nameController.text} logged — ${_kcalController.text} kcal',
          style: AppTextStyles.label.copyWith(
            color: AppColors.cream, fontSize: 13),
        ),
      ),
    );
    _reset();
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.background),
      child: SafeArea(bottom: false,
        child: !state.isPremium
            ? _buildLockedScreen()
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _screenState == 'split'
                    ? _buildSplitView()
                    : _screenState == 'loading'
                        ? _buildLoadingView()
                        : _screenState == 'results'
                            ? _buildResultsView()
                            : _buildErrorView(),
              ),
      ),
    );
  }

  // ── Locked screen ─────────────────────────────────────────
  Widget _buildLockedScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('analyse', style: AppTextStyles.body),
          Text('AI food\nanalysis',
            style: AppTextStyles.titleLarge.copyWith(fontSize: 40)),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.blush.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: AppColors.blush.withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome,
                      color: AppColors.blush, size: 24),
                  ),
                ),
                const SizedBox(height: 16),
                Text('elaarra premium',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 24),
                  textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Point your camera at any meal or nutrition label and let AI do the work.',
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _openPaywall,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('See premium plans',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.button),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureTile(Icons.camera_alt_outlined,
            'Scan your meal for an instant calorie estimate'),
          const SizedBox(height: 8),
          _buildFeatureTile(Icons.qr_code_scanner_outlined,
            'Scan any nutrition label to log exact macros'),
          const SizedBox(height: 8),
          _buildFeatureTile(Icons.edit_outlined,
            'Review and edit results before they\'re logged'),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blush, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: AppTextStyles.label.copyWith(
              color: AppColors.blush, fontSize: 12,
              fontWeight: FontWeight.w300,
            )),
          ),
        ],
      ),
    );
  }

  // ── Split view ────────────────────────────────────────────
  Widget _buildSplitView() {
    return SingleChildScrollView(
      key: const ValueKey('split'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('analyse', style: AppTextStyles.body),
          Text('What would\nyou like to do?',
            style: AppTextStyles.titleLarge.copyWith(fontSize: 40)),
          const SizedBox(height: 28),
          _buildModeCard(
            mode: 'food',
            icon: Icons.camera_alt_outlined,
            title: 'Scan a meal',
            subtitle: 'Point at your food for an AI calorie estimate',
            isHighlighted: true,
          ),
          const SizedBox(height: 12),
          _buildModeCard(
            mode: 'label',
            icon: Icons.qr_code_scanner_outlined,
            title: 'Scan a label',
            subtitle: 'Read nutrition info directly from packaging',
            isHighlighted: false,
          ),
          const SizedBox(height: 24),
          Text(
            'Results are estimates — always review before logging',
            style: AppTextStyles.caption.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isHighlighted,
  }) {
    return GestureDetector(
      onTap: () => _selectMode(mode),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isHighlighted
              ? Colors.white.withOpacity(0.95)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isHighlighted
                ? Colors.transparent
                : AppColors.blush.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? AppColors.cream
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isHighlighted
                      ? AppColors.blush
                      : AppColors.blush.withOpacity(0.3),
                ),
              ),
              child: Icon(icon,
                color: isHighlighted ? AppColors.midBrown : AppColors.blush,
                size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 20,
                    color: isHighlighted
                        ? AppColors.darkBrown
                        : AppColors.cream,
                  )),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppTextStyles.label.copyWith(
                    fontSize: 11,
                    color: isHighlighted
                        ? AppColors.midBrown
                        : AppColors.blush,
                    fontWeight: FontWeight.w300,
                  )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
              color: isHighlighted
                  ? AppColors.sienna
                  : AppColors.blush.withOpacity(0.4),
              size: 14),
          ],
        ),
      ),
    );
  }

  // ── Loading view ──────────────────────────────────────────
  Widget _buildLoadingView() {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.cream, strokeWidth: 1.5),
          const SizedBox(height: 24),
          Text(
            _imageFile == null
                ? 'Opening camera...'
                : _mode == 'food'
                    ? 'Analysing your meal...'
                    : 'Reading the label...',
            style: AppTextStyles.titleLarge.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            'This usually takes a few seconds.',
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Results view ──────────────────────────────────────────
  Widget _buildResultsView() {
    return SingleChildScrollView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('analyse', style: AppTextStyles.body),
          Text('Here\'s what\nwe found',
            style: AppTextStyles.titleLarge.copyWith(fontSize: 40)),
          const SizedBox(height: 20),

          // Photo preview
          if (_imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _imageFile!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined,
                    color: AppColors.blush.withOpacity(0.4), size: 32),
                  const SizedBox(height: 6),
                  Text('Photo preview',
                    style: AppTextStyles.caption.copyWith(fontSize: 10)),
                ],
              ),
            ),
          const SizedBox(height: 14),

          // AI result card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _result?.isLabelScan == true
                      ? 'LABEL SCANNED'
                      : 'AI IDENTIFIED',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 9,
                    color: AppColors.midBrown,
                    letterSpacing: 0.14,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 22),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: Icon(Icons.edit_outlined,
                      size: 14,
                      color: AppColors.sienna.withOpacity(0.6)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildEditableMacro('kcal', _kcalController, primary: true),
                    const SizedBox(width: 8),
                    _buildEditableMacro('protein', _proteinController),
                    const SizedBox(width: 8),
                    _buildEditableMacro('carbs', _carbsController),
                    const SizedBox(width: 8),
                    _buildEditableMacro('fat', _fatController),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tap any value to edit',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10, color: AppColors.midBrown),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              GestureDetector(
                onTap: _reset,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.blush.withOpacity(0.3)),
                  ),
                  child: Text('Try again',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.cream)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _logMeal(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('Log this meal',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.button),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Error view ────────────────────────────────────────────
  Widget _buildErrorView() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined,
              color: AppColors.blush.withOpacity(0.4), size: 48),
            const SizedBox(height: 20),
            Text('Let\'s try that again',
              style: AppTextStyles.titleLarge.copyWith(fontSize: 24),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong. Please try again.',
              style: AppTextStyles.body.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _reset,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('Try again', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableMacro(
    String label,
    TextEditingController controller, {
    bool primary = false,
  }) {
    return Expanded(
      flex: primary ? 2 : 1,
      child: Column(
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: primary ? 28 : 18,
              color: AppColors.darkBrown,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Text(label, style: AppTextStyles.label.copyWith(
            fontSize: 9, color: AppColors.midBrown,
          )),
        ],
      ),
    );
  }
}
