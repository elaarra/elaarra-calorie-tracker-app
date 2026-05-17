import 'package:flutter/material.dart';

class AppColors {
  static const darkBrown = Color(0xFF3D1A10);
  static const midBrown  = Color(0xFF7A3B2E);
  static const sienna    = Color(0xFFC4735A);
  static const blush     = Color(0xFFE8B49A);
  static const cream     = Color(0xFFFAF2EE);
  static const error     = Color(0xFFE57373);
}

class AppGradient {
  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.darkBrown, AppColors.midBrown, AppColors.sienna],
    stops: [0.0, 0.55, 1.0],
  );
}

class AppTextStyles {
  static const String _serif  = 'CormorantGaramond';
  static const String _sans   = 'Outfit';

  // Brand mark — used for logo text fallback
  static const TextStyle brandMark = TextStyle(
    fontFamily: _serif,
    fontWeight: FontWeight.w300,
    fontSize: 32,
    color: AppColors.cream,
    letterSpacing: 4,
  );

  // Large display titles — Cormorant Garamond
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _serif,
    fontWeight: FontWeight.w300,
    fontSize: 36,
    color: AppColors.cream,
    height: 1.1,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _serif,
    fontWeight: FontWeight.w400,
    fontSize: 24,
    color: AppColors.darkBrown,
    height: 1.2,
  );

  // Body text — Outfit
  static const TextStyle body = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w300,
    fontSize: 15,
    color: AppColors.blush,
    height: 1.6,
  );

  // Labels — Outfit
  static const TextStyle label = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.cream,
    height: 1.4,
  );

  // Captions — Outfit
  static const TextStyle caption = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w300,
    fontSize: 12,
    color: AppColors.blush,
    height: 1.4,
  );

  // Buttons — Outfit
  static const TextStyle button = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: AppColors.darkBrown,
    letterSpacing: 0.2,
  );

  // Input values — Outfit
  static const TextStyle inputValue = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w300,
    fontSize: 32,
    color: AppColors.cream,
  );
}
