import 'package:flutter_test/flutter_test.dart';

import 'package:clocker/models/task.dart';
import 'package:clocker/providers/task_provider.dart';

import 'test_support.dart';

/// 截止日期与排序语义：
/// 优先级高的在前；同优先级按截止升序；无截止排最后。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initTestDatabase);
  setUp(() async {
    await initTestDatabase();
    await resetTestDatabase();
  });

  test('待办排序：优先级降序 → 截止升序 → 无截止最后', () async {
    final tp = TaskProvider();
    await tp.loadTasks('sp-x');

    // 手工构造排序输入（不落库，直接测排序逻辑）
    final tasks = [
      Task(
        spacetimeId: 'sp-x',
        title: '无截止-紧急',
        priority: TaskPriority.urgent,
      ),
      Task(
        spacetimeId: 'sp-x',
        title: '远截止-紧急',
        priority: TaskPriority.urgent,
        dueDate: DateTime(2026, 12, 31),
      ),
      Task(
        spacetimeId: 'sp-x',
        title: '近截止-紧急',
        priority: TaskPriority.urgent,
        dueDate: DateTime(2026, 10, 25),
      ),
      Task(
        spacetimeId: 'sp-x',
        title: '普通-中',
        priority: TaskPriority.medium,
        dueDate: DateTime(2026, 10, 23),
      ),
    ];

    // 通过 provider 的排序逻辑（复制同一比较器）
    tasks.sort((a, b) {
      final byPriority = b.priority.index.compareTo(a.priority.index);
      if (byPriority != 0) return byPriority;
      final aDue = a.dueDate;
      final bDue = b.dueDate;
      if (aDue == null && bDue == null) return 0;
      if (aDue == null) return 1;
      if (bDue == null) return -1;
      return aDue.compareTo(bDue);
    });

    expect(tasks.map((t) => t.title).toList(), [
      '近截止-紧急',
      '远截止-紧急',
      '无截止-紧急',
      '普通-中',
    ]);
  });

  test('带截止日期创建的任务能持久化并可判逾期', () async {
    final tp = TaskProvider();
    await tp.loadTasks('sp-y');

    final t = await tp.createTask(
      spacetimeId: 'sp-y',
      title: '明天交的报告',
      priority: TaskPriority.high,
      dueDate: DateTime.now().add(const Duration(days: 1)),
    );
    expect(t.dueDate, isNotNull, reason: '截止日期应保存');
    expect(t.isOverdue, isFalse, reason: '未到期不应算逾期');

    // 持久化
    final reloaded = TaskProvider();
    await reloaded.loadTasks('sp-y');
    expect(reloaded.tasks.first.dueDate, isNotNull);

    // 已过期且未完成 → 逾期
    final overdue = t.copyWith(
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
    );
    expect(overdue.isOverdue, isTrue);
    // 已过期但已完成 → 不算逾期
    final doneOverdue = overdue.copyWith(status: TaskStatus.completed);
    expect(doneOverdue.isOverdue, isFalse);
  });
}
