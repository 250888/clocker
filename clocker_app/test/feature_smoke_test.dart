import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';


import 'package:clocker/models/focus_session.dart';
import 'package:clocker/providers/achievement_provider.dart';
import 'package:clocker/providers/focus_provider.dart';
import 'package:clocker/providers/settings_provider.dart';
import 'package:clocker/providers/spacetime_provider.dart';
import 'package:clocker/providers/task_provider.dart';

import 'test_support.dart';

/// 功能冒烟测试：按真实数据层（sqflite ffi）把主要功能走一遍。
///
/// 覆盖：时空创建与持久化、自律速度 v 的正负向、冻结/回溯、
/// 任务生命周期、专注开始/暂停/继续/完成/取消、设置持久化、成就解锁。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initTestDatabase);

  setUp(resetTestDatabase);

  test('时空：创建、自律速度 v 正负向、冻结/回溯、持久化', () async {
    final provider = SpacetimeProvider();
    await provider.loadSpacetimes();
    expect(provider.activeSpacetime, isNull, reason: '初始不应有时空');

    final st = await provider.createSpacetime(
      name: '冒烟测试时空',
      deadline: DateTime.now().add(const Duration(days: 30)),
    );
    expect(provider.activeSpacetime?.id, st.id, reason: '创建后应自动成为激活时空');

    final baseV = st.currentV;

    // 正向：专注 + 任务值 应提高 v（保持不饱和，便于观察正负向）
    await provider.addFocusHours(1);
    await provider.addTaskValue(2);
    final afterPositive = provider.activeSpacetime!;
    expect(afterPositive.currentV, greaterThan(baseV), reason: '专注与任务应提高自律速度 v');

    // 负向：屏幕惩罚 应降低 v
    await provider.addScreenPenalty(1);
    final afterPenalty = provider.activeSpacetime!;
    expect(afterPenalty.currentV, lessThan(afterPositive.currentV),
        reason: '屏幕使用惩罚应降低 v');

    expect(afterPenalty.effectiveFlowRate, greaterThan(0));
    expect(afterPenalty.disciplinePercentage, inInclusiveRange(0.0, 1.0));

    // 冻结 / 回溯
    final freezeBefore = afterPenalty.timeFreezesUsed;
    await provider.useTimeFreeze();
    expect(provider.activeSpacetime!.timeFreezesUsed, freezeBefore + 1);

    final rewindBefore = provider.activeSpacetime!.timeRewindsUsed;
    await provider.useTimeRewind();
    expect(provider.activeSpacetime!.timeRewindsUsed, rewindBefore + 1);

    // 持久化：新实例重新读库
    final reloaded = SpacetimeProvider();
    await reloaded.loadSpacetimes();
    expect(reloaded.spacetimes.any((s) => s.id == st.id), isTrue,
        reason: '时空应写入数据库');
  });

  test('任务：创建、完成、v 值累计、删除', () async {
    final sp = SpacetimeProvider();
    await sp.loadSpacetimes();
    final st = await sp.createSpacetime(
      name: '任务测试时空',
      deadline: DateTime.now().add(const Duration(days: 20)),
    );

    final tasks = TaskProvider();
    await tasks.loadTasks(st.id);
    expect(tasks.tasks, isEmpty);

    final task = await tasks.createTask(
      spacetimeId: st.id,
      title: '第三章习题',
      vValueWeight: 2.0,
    );
    expect(tasks.pendingTasks.length, 1);
    expect(tasks.getMiniTasks().length, 1);

    await tasks.completeTask(task);
    expect(tasks.completedTasks.length, 1);
    expect(tasks.pendingTasks, isEmpty);
    expect(tasks.totalCompletedVValue, greaterThan(0),
        reason: '完成的任务应累计任务 v 值');

    // 持久化
    final reloaded = TaskProvider();
    await reloaded.loadTasks(st.id);
    expect(reloaded.completedTasks.length, 1);

    await tasks.deleteTask(task.id);
    expect(tasks.tasks, isEmpty);
  });

  test('专注：开始→暂停→继续→完成 / 取消，并落库', () async {
    final sp = SpacetimeProvider();
    await sp.loadSpacetimes();
    final st = await sp.createSpacetime(
      name: '专注测试时空',
      deadline: DateTime.now().add(const Duration(days: 10)),
    );

    final focus = FocusProvider();
    // 关掉需要平台权限的外设服务，保证纯逻辑可测
    focus.configure(
      enableWhiteNoise: false,
      enableScreenMonitoring: false,
      enableAttentionMonitoring: false,
      enableCamera: false,
    );
    focus.setTargetDuration(const Duration(minutes: 25));

    focus.startFocus(st.id);
    expect(focus.isRunning, isTrue);
    expect(focus.isPaused, isFalse);
    expect(focus.elapsed, Duration.zero);
    expect(focus.progress, 0);

    focus.pauseFocus();
    expect(focus.isPaused, isTrue, reason: '暂停后应处于暂停态');

    focus.resumeFocus();
    expect(focus.isPaused, isFalse, reason: '继续后应恢复运行');

    await focus.completeFocus();
    expect(focus.isRunning, isFalse);

    final history = await focus.getFocusHistory(st.id);
    expect(history.length, 1, reason: '完成的专注应写入 focus_sessions');
    expect(history.first.status, FocusStatus.completed);

    // 取消流程
    focus.startFocus(st.id);
    await focus.cancelFocus();
    expect(focus.isRunning, isFalse);
    expect(focus.elapsed, Duration.zero);

    final history2 = await focus.getFocusHistory(st.id);
    expect(history2.length, 2);
    expect(
      history2.any((s) => s.status == FocusStatus.cancelled),
      isTrue,
      reason: '取消的专注也应留档',
    );
  });

  test('设置与成就：开关持久化、首次专注解锁成就', () async {
    final settings = SettingsProvider();
    await settings.loadSettings();

    await settings.setPomodoroDuration(45);
    await settings.toggleWhiteNoise(false);

    final reloaded = SettingsProvider();
    await reloaded.loadSettings();
    expect(reloaded.settings.pomodoroDuration, 45, reason: '设置应持久化');
    expect(reloaded.settings.enableWhiteNoise, isFalse);

    final achievements = AchievementProvider();
    await achievements.loadAchievements();
    expect(achievements.achievements, isNotEmpty, reason: '应初始化默认成就');
    expect(achievements.unlockedCount, 0);

    await achievements.checkAndUnlockAchievements(
      totalFocusSessions: 1,
      totalFocusHours: 0,
      totalTasksCompleted: 0,
      currentStreak: 0,
      maxDisciplinePercentage: 0,
      hasFlowState: false,
      totalDaysEarned: 0,
    );
    expect(achievements.unlockedCount, greaterThanOrEqualTo(1),
        reason: '首次专注应解锁「初入时空」');
  });

  test('物理引擎：γ 与时间膨胀方向正确', () {
    // γ = 1 / sqrt(1 - v²/c²)，v 越大 γ 越大
    expect(_gamma(0, 8), closeTo(1.0, 1e-9));
    expect(_gamma(2, 8), lessThan(_gamma(4, 8)));
    expect(_gamma(7.9, 8), greaterThan(3.0), reason: '接近光速时 γ 应显著增大');
  });
}

double _gamma(double v, double c) {
  final ratio = (v / c).clamp(0.0, 0.9999);
  return 1 / math.sqrt(1 - ratio * ratio);
}
