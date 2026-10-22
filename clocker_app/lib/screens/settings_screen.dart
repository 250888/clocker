import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/achievement_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/dawn_backdrop.dart';

/// 时空规则：分组列表 + 开关 + 危险操作。
///
/// 视觉约定：分区标题 10px/字距 2.6；行高 ≥44px；分隔只用 1px 发丝线。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('时空规则'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DawnBackdrop(showTrails: false)),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                  20,
                  40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('流 速 与 节 奏'),
                    _sliderRow(
                      label: '番茄钟时长',
                      value: '${settings.settings.pomodoroDuration} 分钟',
                      slider: Slider(
                        value: settings.settings.pomodoroDuration.toDouble(),
                        min: 15,
                        max: 90,
                        divisions: 5,
                        onChanged: (v) =>
                            settings.setPomodoroDuration(v.toInt()),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _section('提 醒'),
                    _switchRow(
                      title: '通知提醒',
                      subtitle: '截止日预警、每日损失报告',
                      value: settings.settings.enableNotifications,
                      onChanged: settings.toggleNotifications,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '摄像头 / 屏幕监控与白噪音在「专注时空」页开关；隐私说明与数据清除在「仪表盘」页底部。',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 10.5,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _section('成 就'),
                    _achievements(),
                    const SizedBox(height: 22),
                    _section('关 于'),
                    _about(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textHint,
          fontSize: 10,
          letterSpacing: 2.6,
        ),
      ),
    );
  }

  Widget _rowShell({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: child,
    );
  }

  Widget _switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _rowShell(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }


  Widget _about() {
    return _rowShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CLOCKER · 钟慢',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
          ),
          const SizedBox(height: 5),
          const Text(
            '版本 1.3.0 · Flutter 跨平台（Web / Windows / Android）',
            style: TextStyle(color: AppColors.textHint, fontSize: 10.5),
          ),
          const SizedBox(height: 5),
          const Text(
            '演示：250888.github.io/clocker',
            style: TextStyle(color: AppColors.textHint, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required String value,
    required Widget slider,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 12,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        slider,
      ],
    );
  }

  Widget _achievements() {
    return Consumer<AchievementProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '已完成',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  '${provider.unlockedCount} / ${provider.totalCount}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: provider.completionRate,
                backgroundColor: AppColors.surfaceLight,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
              children: provider.achievements
                  .take(8)
                  .map((a) => AchievementBadge(achievement: a))
                  .toList(),
            ),
          ],
        );
      },
    );
  }

}
