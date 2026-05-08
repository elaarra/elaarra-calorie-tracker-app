import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class AnalyseScreen extends StatelessWidget {
  const AnalyseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.background),
      child: const SafeArea(
        child: Center(
          child: Text('Analyse', style: AppTextStyles.titleLarge),
        ),
      ),
    );
  }
}
