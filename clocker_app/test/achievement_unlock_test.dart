import 'package:flutter_test/flutter_test.dart';

import 'package:clocker/core/utils/database_factory.dart' as app_db;
import 'package:clocker/models/focus_session.dart';
import 'package:clocker/models/task.dart';
import 'package:clocker/providers/achievement_provider.dart';
import 'package:clocker/providers/spacetime_provider.dart';

import 'test_support.dart';

/// 成就系统端到端：真实数据聚合并解锁（此前 checkAndUnlockAchievements 无任何调用点）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initTestDatabase);
  setUp(() async {
    await initTestDatabase();
    await resetTestDatabase();
  });

  test('首次专注 + 十小时 + 心流 + 十任务 → 解锁对应成就', () async {
    final sp = SpacetimeProvider();
    await sp.loadSpacetimes();
    final st = await sp.createSpacetime(
      name: '成就测试',
      deadline: DateTime.now().add(const Duration(days: 20)),
    );
    final db = app_db.DatabaseFactory.create();

    // 三场已完成专注，其中一场心流，累计 10.5 小时
    for (final spec in [
      (DateTime.now().subtract(const Duration(days: 2, hours: 3)), 4.0, false),
      (DateTime.now().subtract(const Duration(hours: 6)), 3.5, true),
      (DateTime.now().subtract(const Duration(hours: 1)), 3.0, false),
    ]) {
      await db.insertFocusSession(FocusSession(
        spacetimeId: st.id,
        mode: FocusMode.deepFocus,
        status: FocusStatus.completed,
        startTime: spec.$1,
        endTime: spec.$1.add(Duration(minutes: (spec.$2 * 60).round())),
        actualDuration: Duration(minutes: (spec.$2 * 60).round()),
        vValueEarned: spec.$2,
        wasFlowState: spec.$3,
      ));
    }

    // 十个已完成任务
    for (var i = 0; i < 10; i++) {
      await db.insertTask(Task(
        spacetimeId: st.id,
        title: '任务 $i',
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
      ));
    }

    final ap = AchievementProvider();
    await ap.loadAchievements();
    expect(ap.unlockedCount, 0, reason: '初始应未解锁');

    await ap.checkNow(st.id);

    final names = ap.unlockedAchievements.map((a) => a.name).toSet();
    expect(names, containsAll(['初入时空', '时间旅行者', '任务终结者', '心流探索者']));
    expect(names, isNot(contains('连续7天')), reason: '只有 2 天记录，不应解锁连续 7 天');

    // 持久化：新实例重读仍解锁
    final reloaded = AchievementProvider();
    await reloaded.loadAchievements();
    expect(reloaded.unlockedAchievements.map((a) => a.name), contains('初入时空'));
  });

  test('连续 7 天有完成专注 → 解锁「连续7天」', () async {
    final sp = SpacetimeProvider();
    await sp.loadSpacetimes();
    final st = await sp.createSpacetime(
      name: '连续测试',
      deadline: DateTime.now().add(const Duration(days: 30)),
    );
    final db = app_db.DatabaseFactory.create();

    final today = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final at = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i))
          .add(const Duration(hours: 9));
      await db.insertFocusSession(FocusSession(
        spacetimeId: st.id,
        mode: FocusMode.deepFocus,
        status: FocusStatus.completed,
        startTime: at,
        endTime: at.add(const Duration(minutes: 60)),
        actualDuration: const Duration(minutes: 60),
        vValueEarned: 1,
      ));
    }

    final ap = AchievementProvider();
    await ap.loadAchievements();
    await ap.checkNow(st.id);
    expect(ap.unlockedAchievements.map((a) => a.name), contains('连续7天'));
  });

  test('成就描述即获得条件，且每条非空', () async {
    final ap = AchievementProvider();
    await ap.loadAchievements();
    expect(ap.achievements.length, 10);
    for (final a in ap.achievements) {
      expect(a.description, isNotEmpty, reason: '${a.name} 应写明获得条件');
    }
  });
}
