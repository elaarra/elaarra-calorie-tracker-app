import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'services/database_service.dart';
import 'utils/theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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

class _AppLoader extends StatefulWidget {
  const _AppLoader({Key? key}) : super(key: key);

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  bool _ready          = false;
  bool _showOnboarding = false;
  bool _showAuth       = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Temporary: force sign out to test auth screen
    await FirebaseAuth.instance.signOut();

    final state = context.read<AppState>();
    await state.init();

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) setState(() { _showAuth = true; _ready = true; });
      return;
    }

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
      return Container(
        decoration: const BoxDecoration(gradient: AppGradient.background),
        child: const Center(
          child: Text('elaarra', style: AppTextStyles.brandMark),
        ),
      );
    }
    if (_showAuth)       return const AuthScreen();
    if (_showOnboarding) return const OnboardingScreen();
    return const MainShell();
  }
}
