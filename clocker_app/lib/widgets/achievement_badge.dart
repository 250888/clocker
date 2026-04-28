import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/achievement.dart';

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;

  const AchievementBadge({
    super.key,
    required this.achievement,
    this.onTap,
  });

  Color get tierColor {
    switch (achievement.tier) {
      case AchievementTier.restFrame:
        return AppColors.textHint;
      case AchievementTier.sublight:
        return AppColors.accent;
      case AchievementTier.lightSpeed:
        return AppColors.primary;
      case AchievementTier.tachyon:
        return AppColors.cosmic4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: achievement.isUnlocked
              ? tierColor.withValues(alpha: 0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: achievement.isUnlocked
              ? Border.all(color: tierColor.withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 28,
                color: achievement.isUnlocked ? null : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              achievement.name,
              style: TextStyle(
                color: achievement.isUnlocked
                    ? AppColors.textPrimary
                    : AppColors.textHint,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            if (achievement.isUnlocked)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  achievement.tierName,
                  style: TextStyle(
                    color: tierColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Icon(Icons.lock, size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
