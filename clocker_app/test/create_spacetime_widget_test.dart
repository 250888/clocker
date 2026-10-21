import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:clocker/core/constants/app_theme.dart';
import 'package:clocker/providers/spacetime_provider.dart';
import 'package:clocker/screens/create_spacetime_screen.dart';

import 'test_support.dart';

/// 创建时空表单：填名称 → 点「生成自律时空」 → 时空真的写进数据库。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initTestDatabase);
  setUp(() async {
    await initTestDatabase();
    await resetTestDatabase();
  });

  testWidgets('创建表单提交后写入数据库并成为激活时空', (tester) async {
    late SpacetimeProvider provider;
    await tester.runAsync(() async {
      provider = SpacetimeProvider();
      await provider.loadSpacetimes();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<SpacetimeProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CreateSpacetimeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // 表单初始状态：没有名称时点提交会被校验拦下
    expect(provider.activeSpacetime, isNull);

    await tester.enterText(find.byType(TextFormField).first, '资料竞赛');
    await tester.pump(const Duration(milliseconds: 200));

    // 表单是 ListView，按钮在末尾：先滚动到底部再找
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 120));
    }
    await tester.pump(const Duration(milliseconds: 300));

    // 点「生成自律时空」
    final submit = find.widgetWithText(ElevatedButton, '生成自律时空');
    expect(submit, findsOneWidget);
    await tester.ensureVisible(submit);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(submit);
    // 真实数据库写入发生在 runAsync 中
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await tester.pump(const Duration(milliseconds: 400));

    expect(provider.activeSpacetime, isNotNull, reason: '提交后应创建并激活时空');
    expect(provider.activeSpacetime!.name, '资料竞赛');

    // 重新读库确认持久化
    await tester.runAsync(() async {
      await provider.loadSpacetimes();
    });
    expect(provider.spacetimes.length, 1);
    expect(provider.spacetimes.first.name, '资料竞赛');
  });
}
