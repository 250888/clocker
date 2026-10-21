import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:clocker/core/constants/app_theme.dart';
import 'package:clocker/providers/achievement_provider.dart';
import 'package:clocker/providers/settings_provider.dart';
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

    await tester.runAsync(() async {
      settings = SettingsProvider();
      await settings.loadSettings();
      achievements = AchievementProvider();
      await achievements.loadAchievements();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: achievements),
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
    expect(find.text('屏幕使用监控'), findsOneWidget);
    expect(find.text('白噪音'), findsOneWidget);
    expect(find.text('清除所有本地数据'), findsOneWidget);
  });
}
