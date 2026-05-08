import 'package:flutter/material.dart';
import 'utils/theme.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() {
  runApp(const ElaarraApp());
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
      home: const OnboardingScreen(),
    );
  }
}
