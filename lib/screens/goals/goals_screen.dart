import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.background),
      child: const SafeArea(
        child: Center(
          child: Text('Goals', style: AppTextStyles.titleLarge),
        ),
      ),
    );
  }
}
