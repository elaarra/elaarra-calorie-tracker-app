import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.background),
      child: const SafeArea(
        child: Center(
          child: Text('Log', style: AppTextStyles.titleLarge),
        ),
      ),
    );
  }
}
