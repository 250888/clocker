import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/focus_session.dart';
import '../models/task.dart';
import '../core/utils/database_factory.dart';

class AchievementProvider extends ChangeNotifier {
  List<Achievement> _achievements = [];
  final DatabaseHelperInterface _db = DatabaseFactory.create();

  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();
  List<Achievement> get lockedAchievements =>
      _achievements.where((a) => !a.isUnlocked).toList();

  int get unlockedCount => unlockedAchievements.length;
  int get totalCount => _achievements.length;
  double get completionRate => totalCount > 0 ? unlockedCount / totalCount : 0;

  Future<void> loadAchievements() async {
    await _db.initAchievements();
    _achievements = await _db.getAllAchievements();
    notifyListeners();
  }

  Future<void> checkAndUnlockAchievements({
    required int totalFocusSessions,
    required double totalFocusHours,
    required int totalTasksCompleted,
    required int currentStreak,
    required double maxDisciplinePercentage,
    required bool hasFlowState,
    required double totalDaysEarned,
  }) async {
    bool anyUnlocked = false;

    for (final achievement in _achievements) {
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;

      switch (achievement.category) {
        case AchievementCategory.focus:
          if (achievement.name == '初入时空' && totalFocusSessions >= 1) {
            shouldUnlock = true;
          } else if (achievement.name == '时间旅行者' && totalFocusHours >= 10) {
            shouldUnlock = true;
          } else if (achievement.name == '亚光速巡航' &&
              maxDisciplinePercentage >= 0.5) {
            shouldUnlock = true;
          } else if (achievement.name == '光速突破' &&
              maxDisciplinePercentage >= 0.9) {
            shouldUnlock = true;
          }
          break;
        case AchievementCategory.task:
          if (achievement.name == '任务终结者' && totalTasksCompleted >= 10) {
            shouldUnlock = true;
          }
          break;
        case AchievementCategory.streak:
          if (achievement.name == '连续7天' && currentStreak >= 7) {
            shouldUnlock = true;
          } else if (achievement.name == '连续30天' && currentStreak >= 30) {
            shouldUnlock = true;
          }
          break;
        case AchievementCategory.special:
          if (achievement.name == '心流探索者' && hasFlowState) {
            shouldUnlock = true;
          } else if (achievement.name == '时空大师' && totalDaysEarned >= 30) {
            shouldUnlock = true;
          } else if (achievement.name == '超光速粒子' && unlockedCount >= 9) {
            shouldUnlock = true;
          }
          break;
      }

      if (shouldUnlock) {
        final idx = _achievements.indexWhere((a) => a.id == achievement.id);
        if (idx >= 0) {
          _achievements[idx] = achievement.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          );
          await _db.updateAchievement(_achievements[idx]);
          anyUnlocked = true;
        }
      }
    }

    if (anyUnlocked) {
      notifyListeners();
    }
  }

  /// 从真实数据计算成就指标并解锁（专注结束 / 任务完成 / 打开报告页时调用）。
  Future<void> checkNow(String spacetimeId) async {
    try {
      if (_achievements.isEmpty) {
        await _db.initAchievements();
        _achievements = await _db.getAllAchievements();
      }

      final sessions = await _db.getFocusSessionsForSpacetime(spacetimeId);
      final tasks = await _db.getTasksForSpacetime(spacetimeId);
      final st = await _db.getSpacetime(spacetimeId);

      final done =
          sessions.where((s) => s.status == FocusStatus.completed).toList();
      final totalSessions = done.length;
      final totalHours = done.fold<double>(
          0, (a, s) => a + s.actualDuration.inMinutes / 60.0);
      final tasksDone =
          tasks.where((t) => t.status == TaskStatus.completed).length;
      final hasFlow = done.any((s) => s.wasFlowState);

      // 连续自律天数：按「有完成专注」的日期计算
      final activeDays = done
          .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
          .toSet();
      final today = DateTime.now();
      var cursor = DateTime(today.year, today.month, today.day);
      if (!activeDays.contains(cursor)) {
        cursor = cursor.subtract(const Duration(days: 1));
      }
      var streak = 0;
      while (activeDays.contains(cursor)) {
        streak += 1;
        cursor = cursor.subtract(const Duration(days: 1));
      }

      await checkAndUnlockAchievements(
        totalFocusSessions: totalSessions,
        totalFocusHours: totalHours,
        totalTasksCompleted: tasksDone,
        currentStreak: streak,
        maxDisciplinePercentage: st?.disciplinePercentage ?? 0,
        hasFlowState: hasFlow,
        totalDaysEarned: st?.timeEarnedDays ?? 0,
      );
    } catch (e) {
      debugPrint('Achievement check error: $e');
    }
  }
}
