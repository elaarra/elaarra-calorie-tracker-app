import 'package:flutter/material.dart';

class AppColors {
  static const Color darkBrown    = Color(0xFF3D1A10);
  static const Color midBrown     = Color(0xFF7A3B2E);
  static const Color sienna       = Color(0xFFC4735A);
  static const Color blush        = Color(0xFFE8B49A);
  static const Color cream        = Color(0xFFFAF2EE);
  static const Color white        = Color(0xFFFFFFFF);
  static const Color inputBg      = Color(0xFFF0D5C8);
  static const Color success      = Color(0xFF4CAF50);
  static const Color error        = Color(0xFFE53935);
}

class AppTextStyles {
  // Brand mark — always lowercase, never override
  static const TextStyle brandMark = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.blush,
    letterSpacing: 0.04,
  );

  // Large editorial titles — on gradient background
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.cream,
    height: 1.12,
  );

  // Section titles — on white/card surfaces  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.darkBrown,
    height: 1.2,
  );

  // Body text — Neue Montreal light
  static const TextStyle body = TextStyle(
    fontFamily: 'NueveMontreal',
    fontSize: 13,
    fontWeight: FontWeight.w300,
    color: AppColors.blush,
    height: 1.65,
    letterSpacing: 0.01,
  );

  // Labels — Neue Montreal regular
  static const TextStyle label = TextStyle(
    fontFamily: 'NueveMontreal',
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.midBrown,
    letterSpacing: 0.0,
  );

  // Step indicator & caps labels
  static const TextStyle caption = TextStyle(
    fontFamily: 'NueveMontreal',
    fontSize: 9,
    fontWeight: FontWeight.w300,
    color: AppColors.blush,
    letterSpacing: 0.12,
  );

  // Input values — Cormorant numbers feel luxurious
  static const TextStyle inputValue = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.darkBrown,
  );

  // Button text
  static const TextStyle button = TextStyle(
    fontFamily: 'NueveMontreal',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.darkBrown,
    letterSpacing: 0.08,
  );
}

class AppGradient {
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.45, 1.0],
    colors: [
      AppColors.darkBrown,
      AppColors.midBrown,
      AppColors.sienna,
    ],
  );
}
