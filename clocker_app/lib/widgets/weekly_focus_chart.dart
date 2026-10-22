import 'package:flutter/material.dart';

import '../core/utils/database_factory.dart';

import '../core/constants/app_colors.dart';
import '../models/focus_session.dart';

/// 近 7 天专注时长（小时），从专注会话按天聚合。
/// 供报告页与单元测试共用，保证口径一致。
List<double> weeklyFocusHours(List<FocusSession> sessions, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final buckets = List<double>.filled(7, 0);
  final today = DateTime(ref.year, ref.month, ref.day);

  for (final s in sessions) {
    final start = s.startTime;
    final days = today.difference(DateTime(start.year, start.month, start.day)).inDays;
    if (days < 0 || days > 6) continue;
    buckets[6 - days] += s.actualDuration.inMinutes / 60.0;
  }
  return buckets;
}

/// 近 7 天专注柱状图（左→右 = 6 天前 → 今天）。
class WeeklyFocusChart extends StatelessWidget {
  const WeeklyFocusChart({super.key, required this.sessions});

  final List<FocusSession> sessions;

  static const List<String> _labels = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final hours = weeklyFocusHours(sessions);
    final maxHours = hours.reduce((a, b) => a > b ? a : b);
    final todayIndex = DateTime.now().weekday - 1; // 0=周一

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '近 7 天 专 注',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 10,
                  letterSpacing: 2.4,
                ),
              ),
              const Spacer(),
              Text(
                '合计 ${hours.fold<double>(0, (a, b) => a + b).toStringAsFixed(1)} h',
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 10.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            hours[i] > 0 ? hours[i].toStringAsFixed(1) : '',
                            style: TextStyle(
                              color: i == todayIndex
                                  ? AppColors.primaryLight
                                  : AppColors.textHint,
                              fontSize: 8.5,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: maxHours <= 0
                                ? 3
                                : 6 + (hours[i] / maxHours) * 62,
                            decoration: BoxDecoration(
                              color: i == todayIndex
                                  ? AppColors.primary
                                  : hours[i] > 0
                                      ? AppColors.primary
                                          .withValues(alpha: 0.45)
                                      : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _labels[i],
                            style: TextStyle(
                              color: i == todayIndex
                                  ? AppColors.primaryLight
                                  : AppColors.textHint,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 只加载一次的容器：进入报告页时从数据库读取专注会话，再交给柱状图。
class WeeklyFocusPanel extends StatefulWidget {
  const WeeklyFocusPanel({super.key, required this.spacetimeId});

  final String spacetimeId;

  @override
  State<WeeklyFocusPanel> createState() => _WeeklyFocusPanelState();
}

class _WeeklyFocusPanelState extends State<WeeklyFocusPanel> {
  List<FocusSession>? _sessions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = DatabaseFactory.create();
      final list = await db.getFocusSessionsForSpacetime(widget.spacetimeId);
      if (mounted) setState(() => _sessions = list);
    } catch (_) {
      if (mounted) setState(() => _sessions = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _sessions;
    if (sessions == null) return const SizedBox.shrink();
    return WeeklyFocusChart(sessions: sessions);
  }
}
