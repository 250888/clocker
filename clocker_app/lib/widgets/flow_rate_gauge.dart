import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/duration_formatter.dart';

class FlowRateGauge extends StatelessWidget {
  final double flowRate;
  final double v0;
  final double vValue;
  final double c;
  final double disciplinePercentage;
  final bool isInFlowState;

  const FlowRateGauge({
    super.key,
    required this.flowRate,
    required this.v0,
    required this.vValue,
    required this.c,
    required this.disciplinePercentage,
    this.isInFlowState = false,
  });

  Color get flowColor {
    if (disciplinePercentage >= 0.6) return AppColors.flowSlow;
    if (disciplinePercentage >= 0.3) return AppColors.flowMedium;
    return AppColors.flowFast;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: isInFlowState
            ? Border.all(color: AppColors.flowSlow, width: 2)
            : null,
        boxShadow: isInFlowState
            ? [
                BoxShadow(
                  color: AppColors.flowSlow.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '当前流速',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (isInFlowState)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.flowSlow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, color: AppColors.flowSlow, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '心流模式',
                        style: TextStyle(
                          color: AppColors.flowSlow,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          CircularPercentIndicator(
            radius: 80,
            lineWidth: 12,
            percent: disciplinePercentage.clamp(0.0, 1.0),
            animation: true,
            animationDuration: 800,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: AppColors.surfaceLight,
            progressColor: flowColor,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DurationFormatter.formatFlowRate(flowRate),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '流速',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetric(context, '自律速度 v', '${vValue.toStringAsFixed(1)}h'),
              Container(
                width: 1,
                height: 30,
                color: AppColors.surfaceLight,
              ),
              _buildMetric(context, '自律极限 c', '${c.toStringAsFixed(0)}h'),
              Container(
                width: 1,
                height: 30,
                color: AppColors.surfaceLight,
              ),
              _buildMetric(
                  context, '自律度', DurationFormatter.formatPercentage(disciplinePercentage)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
