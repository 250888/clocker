import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../core/utils/database_helper.dart';

class AchievementProvider extends ChangeNotifier {
  List<Achievement> _achievements = [];
  final DatabaseHelper _db = DatabaseHelper();

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
          } else if (achievement.name == '超光速粒子' &&
              unlockedCount >= 9) {
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
}
