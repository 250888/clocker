import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:clocker/core/constants/app_theme.dart';
import 'package:clocker/providers/achievement_provider.dart';
import 'package:clocker/providers/focus_provider.dart';
import 'package:clocker/providers/settings_provider.dart';
import 'package:clocker/providers/spacetime_provider.dart';
import 'package:clocker/screens/settings_screen.dart';

import 'test_support.dart';

/// 规则页整页渲染：锁定的徽章必须显示「获得条件」，不能显示奖励。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initTestDatabase);
  setUp(() async {
    await initTestDatabase();
    await resetTestDatabase();
  });

  testWidgets('规则页成就区：未解锁徽章显示条件文案', (tester) async {
    late SettingsProvider settings;
    late AchievementProvider achievements;
    final focus = FocusProvider();
    final spacetimes = SpacetimeProvider();

    await tester.runAsync(() async {
      settings = SettingsProvider();
      await settings.loadSettings();
      achievements = AchievementProvider();
      await achievements.loadAchievements();
      await spacetimes.loadSpacetimes();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: achievements),
          ChangeNotifierProvider.value(value: focus),
          ChangeNotifierProvider.value(value: spacetimes),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(achievements.unlockedCount, 0, reason: '初始应全部未解锁');
    // 前两条成就的条件必须出现在页面上
    expect(find.text('完成第一次专注'), findsOneWidget, reason: '「初入时空」条件应可见');
    expect(find.text('累计专注10小时'), findsOneWidget, reason: '「时间旅行者」条件应可见');
    // 未解锁时不显示奖励
    expect(find.text('解锁基础主题'), findsNothing, reason: '未解锁不应显示奖励');
  });
}
