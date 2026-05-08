import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.background),
      child: const SafeArea(
        child: Center(
          child: Text('Home', style: AppTextStyles.titleLarge),
        ),
      ),
    );
  }
}
