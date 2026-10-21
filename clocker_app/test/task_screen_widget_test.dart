import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:clocker/core/constants/app_theme.dart';
import 'package:clocker/models/task.dart';
import 'package:clocker/providers/spacetime_provider.dart';
import 'package:clocker/providers/task_provider.dart';
import 'package:clocker/screens/task_screen.dart';

import 'test_support.dart';

/// 真实 TaskScreen（真 provider + 真 sqlite）渲染与切换 Tab 的行为验证。
///
/// 注意：widget 测试跑在 FakeAsync 中，真实数据库的 Future 不会自动完成，
/// 所有落库操作必须放在 `tester.runAsync` 里。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initTestDatabase);
  setUp(() async {
    await initTestDatabase();
    await resetTestDatabase();
  });

  testWidgets('任务页：待办/已完成 Tab 均能渲染真实任务', (tester) async {
    late SpacetimeProvider spacetime;
    late TaskProvider tasks;

    await tester.runAsync(() async {
      spacetime = SpacetimeProvider();
      await spacetime.loadSpacetimes();
      final st = await spacetime.createSpacetime(
        name: '任务页测试',
        deadline: DateTime.now().add(const Duration(days: 15)),
      );

      tasks = TaskProvider();
      await tasks.loadTasks(st.id);
      final pending = await tasks.createTask(
        spacetimeId: st.id,
        title: '第三章习题',
        vValueWeight: 2.0,
        priority: TaskPriority.high,
      );
      await tasks.createTask(
        spacetimeId: st.id,
        title: '英语单词',
        vValueWeight: 1.0,
      );
      await tasks.completeTask(pending);

      // 数据层先自检，避免把「数据没写进去」误判成「UI 没渲染」
      expect(tasks.completedTasks.length, 1);
      expect(tasks.pendingTasks.length, 1);
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: spacetime),
          ChangeNotifierProvider.value(value: tasks),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TaskScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Tab 0 = 待办，Tab 1 = 已完成，Tab 2 = 逾期
    await tester.tap(find.byType(Tab).at(1));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('第三章习题'), findsOneWidget);

    await tester.tap(find.byType(Tab).at(0));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('英语单词'), findsOneWidget);
  });
}
