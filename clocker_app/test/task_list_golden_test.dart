@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clocker/core/constants/app_colors.dart';
import 'package:clocker/core/constants/app_theme.dart';
import 'package:clocker/models/task.dart';
import 'package:clocker/widgets/dawn_backdrop.dart';
import 'package:clocker/widgets/task_card.dart';

void main() {
  testWidgets('task list rows render', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const goldenKey = Key('task-list-golden');

    final tasks = <Task>[
      Task(
        spacetimeId: 'sp',
        title: '高数 · 第三章习题',
        vValueWeight: 2.0,
        priority: TaskPriority.high,
        dueDate: DateTime(2026, 10, 23),
        subtasks: const ['1-10 题', '11-20 题'],
        completedSubtasks: const ['1-10 题'],
      ),
      Task(
        spacetimeId: 'sp',
        title: '物理实验报告',
        vValueWeight: 1.5,
        status: TaskStatus.inProgress,
        priority: TaskPriority.urgent,
        dueDate: DateTime(2026, 10, 24),
      ),
      Task(
        spacetimeId: 'sp',
        title: '英语单词 List 12',
        vValueWeight: 1.0,
        priority: TaskPriority.medium,
        dueDate: DateTime(2026, 10, 20),
      ),
      Task(
        spacetimeId: 'sp',
        title: 'LeetCode 三题',
        vValueWeight: 1.0,
        status: TaskStatus.completed,
        priority: TaskPriority.low,
        completedAt: DateTime(2026, 10, 21),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: RepaintBoundary(
            key: goldenKey,
            child: Stack(
              children: [
                const Positioned.fill(child: DawnBackdrop(showTrails: false)),
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 96, 20, 24),
                  children: [
                    const Text(
                      '今 日 任 务',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 10,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final t in tasks)
                      TaskCard(
                        task: t,
                        onTap: () {},
                        onComplete: () {},
                        onDelete: () {},
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await expectLater(
      find.byKey(goldenKey),
      matchesGoldenFile('goldens/task_list.png'),
    );
  });
}
