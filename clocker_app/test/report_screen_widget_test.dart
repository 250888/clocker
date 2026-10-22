import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:clocker/core/constants/app_theme.dart';
import 'package:clocker/providers/spacetime_provider.dart';
import 'package:clocker/screens/report_screen.dart';

import 'test_support.dart';

/// 真实 ReportScreen（真 provider + 真 sqlite）渲染验证。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initTestDatabase);
  setUp(() async {
    await initTestDatabase();
    await resetTestDatabase();
  });

  testWidgets('报告页：净赚主视觉与三项指标渲染', (tester) async {
    late SpacetimeProvider spacetime;

    await tester.runAsync(() async {
      spacetime = SpacetimeProvider();
      await spacetime.loadSpacetimes();
      await spacetime.createSpacetime(
        name: '报告页测试',
        deadline: DateTime.now().add(const Duration(days: 12)),
      );
      await spacetime.addFocusHours(42);
      await spacetime.addTaskValue(18);
      await spacetime.addScreenPenalty(6);
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: spacetime)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ReportScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // 主视觉
    expect(find.text('累 计 净 赚'), findsOneWidget, reason: '数值是累计口径，标签必须一致');
    // 三项指标（数值来自真实 provider 数据）
    expect(find.text('42.0h'), findsOneWidget);
    expect(find.text('18.0h'), findsOneWidget);
    expect(find.text('总专注'), findsOneWidget);
    expect(find.text('任务值'), findsOneWidget);
    expect(find.text('当前流速'), findsOneWidget);
    // 图表与解读区仍在
    expect(find.textContaining('流速曲线'), findsOneWidget);
  });
}
