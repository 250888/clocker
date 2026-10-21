import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/achievement.dart';

/// 成就徽章（仪器风）：1px 描边方格 + 线性图标 + 单行名称。
///
/// 刻意不用彩色 emoji 与彩色底：成就的价值来自「已解锁/未解锁」的明暗对比。
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.achievement,
    this.onTap,
  });

  final Achievement achievement;
  final VoidCallback? onTap;

  Color get _tierColor {
    switch (achievement.tier) {
      case AchievementTier.restFrame:
        return AppColors.textHint;
      case AchievementTier.sublight:
        return AppColors.accentDark;
      case AchievementTier.lightSpeed:
        return AppColors.primary;
      case AchievementTier.tachyon:
        return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final color = unlocked ? _tierColor : AppColors.textHint;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: unlocked
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: unlocked
                ? AppColors.primary.withValues(alpha: 0.45)
                : AppColors.hairline,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              unlocked
                  ? Icons.workspace_premium_outlined
                  : Icons.lock_outline,
              size: 18,
              color: unlocked ? color : AppColors.hairlineStrong,
            ),
            const SizedBox(height: 6),
            Text(
              achievement.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: unlocked ? AppColors.textPrimary : AppColors.textHint,
                fontSize: 9.5,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
