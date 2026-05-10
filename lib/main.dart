import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'services/database_service.dart';
import 'utils/theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable edge-to-edge enforcement
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF3D1A10),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await dotenv.load(fileName: '.env');
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
        child: Center(
          child: Image.asset('assets/images/logo_cream_darkBG.png', height: 36),
        ),
      );
    }
    if (_showAuth)       return const AuthScreen();
    if (_showOnboarding) return const OnboardingScreen();
    return const MainShell();
  }
}
