import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'services/database_service.dart';
import 'utils/theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const ElaarraApp(),
    ),
  );
}

class ElaarraApp extends StatelessWidget {
  const ElaarraApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'elaarra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.darkBrown,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.sienna,
          brightness: Brightness.dark,
        ),
      ),
      home: const _AppLoader(),
    );
  }
}

// Loads app state from SQLite before deciding which screen to show
class _AppLoader extends StatefulWidget {
  const _AppLoader({Key? key}) : super(key: key);

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  bool _ready           = false;
  bool _showOnboarding  = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Initialise app state from SQLite
    final state = context.read<AppState>();
    await state.init();

    // Check if onboarding has been completed
    final onboardingDone =
        await DatabaseService.instance.isOnboardingComplete();

    if (mounted) {
      setState(() {
        _showOnboarding = !onboardingDone;
        _ready          = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      // Splash screen while loading
      return Container(
        decoration: const BoxDecoration(gradient: AppGradient.background),
        child: const Center(
          child: Text(
            'elaarra',
            style: AppTextStyles.brandMark,
          ),
        ),
      );
    }
    return _showOnboarding ? const OnboardingScreen() : const MainShell();
  }
}
