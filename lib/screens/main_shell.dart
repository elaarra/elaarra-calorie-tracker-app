import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';
import 'home/home_screen.dart';
import 'log/log_screen.dart';
import 'analyse/analyse_screen.dart';
import 'goals/goals_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LogScreen(),
    AnalyseScreen(),
    GoalsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.darkBrown,
      systemNavigationBarDividerColor: AppColors.darkBrown,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBrown,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      color: AppColors.darkBrown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top border line
          Container(
            height: 0.3,
            color: AppColors.blush,
          ),
          // Nav items above safe area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.edit_outlined, Icons.edit_rounded, 'Log'),
                _buildAnalyseItem(),
                _buildNavItem(3, Icons.trending_up_outlined, Icons.trending_up, 'Results'),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final selected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.cream.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: selected
                  ? AppColors.cream
                  : AppColors.blush.withOpacity(0.5),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: selected
                    ? AppColors.cream
                    : AppColors.blush.withOpacity(0.5),
                fontSize: 10,
                letterSpacing: 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyseItem() {
    final selected = _currentIndex == 2;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.cream
              : AppColors.cream.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              color: selected ? AppColors.darkBrown : AppColors.cream,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              'Analyse',
              style: AppTextStyles.caption.copyWith(
                color: selected ? AppColors.darkBrown : AppColors.cream,
                fontSize: 10,
                letterSpacing: 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
