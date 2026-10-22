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

/// 真实 SettingsScreen（真 provider + 真 sqlite）渲染验证。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initTestDatabase);
  setUp(() async {
    await initTestDatabase();
    await resetTestDatabase();
  });

  testWidgets('规则页：分组、开关与危险操作均渲染', (tester) async {
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

    expect(find.text('时空规则'), findsOneWidget);
    expect(find.text('流 速 与 节 奏'), findsOneWidget);
    expect(find.text('番茄钟时长'), findsOneWidget);
    expect(find.text('提 醒'), findsOneWidget);
    expect(find.text('通知提醒'), findsOneWidget);
    expect(find.text('关 于'), findsOneWidget);
    expect(find.text('CLOCKER · 钟慢'), findsOneWidget);
    // 新分区：流速参数 / 专注统计 / 时空道具
    expect(find.text('流 速 参 数'), findsOneWidget);
    expect(find.text('专 注 统 计'), findsOneWidget);
    expect(find.text('时 空 道 具'), findsOneWidget);
    expect(find.text('惩罚基准流速 v₀'), findsOneWidget);
    expect(find.text('流速模式'), findsOneWidget);
  });
}
