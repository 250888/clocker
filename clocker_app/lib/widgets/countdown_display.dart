import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/duration_formatter.dart';

class CountdownDisplay extends StatelessWidget {
  final double appDaysRemaining;
  final int realDaysRemaining;
  final double flowRate;
  final double timeEarned;
  final double timeLost;

  const CountdownDisplay({
    super.key,
    required this.appDaysRemaining,
    required this.realDaysRemaining,
    required this.flowRate,
    this.timeEarned = 0,
    this.timeLost = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCountdown(
                context,
                'APP内剩余',
                DurationFormatter.formatDays(appDaysRemaining),
                flowRate <= 1.0 ? AppColors.flowSlow : AppColors.flowFast,
                Icons.access_time,
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.surfaceLight,
              ),
              _buildCountdown(
                context,
                '现实剩余',
                '$realDaysRemaining天',
                AppColors.textPrimary,
                Icons.today,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeStat(
                  context,
                  '已赚取',
                  DurationFormatter.formatDays(timeEarned),
                  AppColors.success,
                  Icons.add_circle_outline,
                ),
                _buildTimeStat(
                  context,
                  '已损失',
                  DurationFormatter.formatDays(timeLost),
                  AppColors.danger,
                  Icons.remove_circle_outline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStat(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
