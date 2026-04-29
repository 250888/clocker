import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/spacetime_provider.dart';
import '../providers/task_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/settings_provider.dart';
import 'home_screen.dart';
import 'focus_screen.dart';
import 'task_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    FocusScreen(),
    TaskScreen(),
    ReportScreen(),
    SettingsScreen(),
  ];

  void navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final settingsProvider = context.read<SettingsProvider>();
      final spacetimeProvider = context.read<SpacetimeProvider>();
      final achievementProvider = context.read<AchievementProvider>();

      await settingsProvider.loadSettings();
      await spacetimeProvider.loadSpacetimes();
      await achievementProvider.loadAchievements();

      if (spacetimeProvider.activeSpacetime != null) {
        final taskProvider = context.read<TaskProvider>();
        await taskProvider.loadTasks(spacetimeProvider.activeSpacetime!.id);
      }
    } catch (e) {
      debugPrint('InitData error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: '仪表盘',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.timer_outlined),
                  activeIcon: Icon(Icons.timer),
                  label: '专注',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.check_circle_outline),
                  activeIcon: Icon(Icons.check_circle),
                  label: '任务',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined),
                  activeIcon: Icon(Icons.bar_chart),
                  label: '报告',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: '规则',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
