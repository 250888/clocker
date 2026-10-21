import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
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
                    _section('监 控 权 限（可 选）'),
                    _switchRow(
                      title: '屏幕使用监控',
                      subtitle: '区分学习与娱乐 APP 时长',
                      value: settings.settings.enableScreenMonitoring,
                      onChanged: settings.toggleScreenMonitoring,
                    ),
                    _switchRow(
                      title: '视觉注意力监控',
                      subtitle: '前置摄像头，全部本地计算',
                      value: settings.settings.enableCameraMonitoring,
                      onChanged: settings.toggleCameraMonitoring,
                    ),
                    const SizedBox(height: 22),
                    _section('声 音 与 提 醒'),
                    _switchRow(
                      title: '通知提醒',
                      subtitle: '截止日预警、每日损失报告',
                      value: settings.settings.enableNotifications,
                      onChanged: settings.toggleNotifications,
                    ),
                    _switchRow(
                      title: '音效',
                      subtitle: '专注完成提示音',
                      value: settings.settings.enableSoundEffects,
                      onChanged: settings.toggleSoundEffects,
                    ),
                    _switchRow(
                      title: '白噪音',
                      subtitle: '与流速同步的沉浸音效',
                      value: settings.settings.enableWhiteNoise,
                      onChanged: settings.toggleWhiteNoise,
                    ),
                    const SizedBox(height: 22),
                    _section('成 就'),
                    _achievements(),
                    const SizedBox(height: 22),
                    _section('隐 私'),
                    const Text(
                      AppStrings.privacyContent,
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        height: 1.9,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _dangerZone(context, settings),
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

  Widget _dangerZone(BuildContext context, SettingsProvider settings) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => _confirmClearData(context, settings),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.danger,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.hairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: const Text(
          '清除所有本地数据',
          style: TextStyle(fontSize: 12, letterSpacing: 1.6),
        ),
      ),
    );
  }

  void _confirmClearData(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认清除数据'),
        content: const Text('将删除所有时空、任务、专注记录与成就数据，且无法恢复。确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              settings.clearAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('所有数据已清除')),
              );
            },
            child: const Text(
              '确认清除',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
