import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'home_screen.dart';
import 'focus_screen.dart';
import 'task_screen.dart';
import 'report_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    FocusScreen(),
    TaskScreen(),
    ReportScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
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
              type: BottomNavigationBarType.fixed,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
