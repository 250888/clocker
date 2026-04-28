import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/duration_formatter.dart';
import '../../models/focus_session.dart';

class PomodoroTimer extends StatelessWidget {
  final Duration elapsed;
  final Duration target;
  final bool isRunning;
  final bool isPaused;
  final FocusMode mode;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onEnd;
  final VoidCallback? onModeChange;

  const PomodoroTimer({
    super.key,
    required this.elapsed,
    required this.target,
    required this.isRunning,
    required this.isPaused,
    required this.mode,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onEnd,
    this.onModeChange,
  });

  double get progress => (elapsed.inSeconds / target.inSeconds).clamp(0.0, 1.0);

  Duration get remaining => target - elapsed;

  Color get modeColor {
    switch (mode) {
      case FocusMode.deepFocus:
        return AppColors.primary;
      case FocusMode.study:
        return AppColors.accent;
      case FocusMode.reading:
        return AppColors.cosmic4;
      case FocusMode.writing:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          if (!isRunning)
            GestureDetector(
              onTap: onModeChange,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: modeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune, color: modeColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      mode.name == 'deepFocus'
                          ? '深度专注'
                          : mode.name == 'study'
                              ? '刷题模式'
                              : mode.name == 'reading'
                                  ? '阅读模式'
                                  : '写作模式',
                      style: TextStyle(
                        color: modeColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.swap_horiz, color: modeColor, size: 14),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(modeColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text(
                    DurationFormatter.formatTimerDisplay(remaining),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRunning
                        ? (isPaused ? '已暂停' : '专注中...')
                        : '准备开始',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isRunning)
                ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始专注'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: modeColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                  ),
                )
              else ...[
                if (isPaused)
                  ElevatedButton.icon(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('继续'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: onPause,
                    icon: const Icon(Icons.pause),
                    label: const Text('暂停'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                    ),
                  ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onEnd,
                  icon: const Icon(Icons.stop),
                  label: const Text('结束'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
