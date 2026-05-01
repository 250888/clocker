import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/achievement_provider.dart';
import '../widgets/achievement_badge.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('时空规则'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, '番茄钟设置'),
                _buildPomodoroDurationSetting(context, settings),
                const SizedBox(height: 20),
                _buildSectionTitle(context, '监控权限（可选）'),
                _buildMonitoringSettings(context, settings),
                const SizedBox(height: 20),
                _buildSectionTitle(context, '其他设置'),
                _buildOtherSettings(context, settings),
                const SizedBox(height: 20),
                _buildSectionTitle(context, '成就'),
                _buildAchievements(context),
                const SizedBox(height: 20),
                _buildPrivacySection(context, settings),
                const SizedBox(height: 20),
                _buildDangerZone(context, settings),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryLight,
            ),
      ),
    );
  }

  Widget _buildPomodoroDurationSetting(BuildContext context, SettingsProvider settings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
              Text('番茄钟时长 (分钟)', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              Text('${settings.settings.pomodoroDuration}分钟',
                  style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: settings.settings.pomodoroDuration.toDouble(),
            min: 15,
            max: 90,
            divisions: 5,
            onChanged: (v) => settings.setPomodoroDuration(v.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringSettings(BuildContext context, SettingsProvider settings) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            '屏幕使用监控',
            '区分学习/娱乐APP时长',
            settings.settings.enableScreenMonitoring,
            (v) => settings.toggleScreenMonitoring(v),
          ),
          _buildSwitchTile(
            '视觉注意力监控',
            '前置摄像头，本地计算',
            settings.settings.enableCameraMonitoring,
            (v) => settings.toggleCameraMonitoring(v),
          ),

        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textHint)),
      value: value,
      onChanged: onChanged,
      dense: true,
    );
  }

  Widget _buildOtherSettings(BuildContext context, SettingsProvider settings) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('通知提醒', style: TextStyle(fontSize: 14)),
            subtitle: Text('截止日预警、每日损失报告', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
            value: settings.settings.enableNotifications,
            onChanged: (v) => settings.toggleNotifications(v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('音效', style: TextStyle(fontSize: 14)),
            subtitle: Text('专注完成提示音', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
            value: settings.settings.enableSoundEffects,
            onChanged: (v) => settings.toggleSoundEffects(v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('白噪音', style: TextStyle(fontSize: 14)),
            subtitle: Text('与流速同步的沉浸音效', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
            value: settings.settings.enableWhiteNoise,
            onChanged: (v) => settings.toggleWhiteNoise(v),
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(BuildContext context) {
    return Consumer<AchievementProvider>(
      builder: (context, achievementProvider, _) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '成就进度',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                  Text(
                    '${achievementProvider.unlockedCount}/${achievementProvider.totalCount}',
                    style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: achievementProvider.completionRate,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.8,
                children: achievementProvider.achievements
                    .take(8)
                    .map((a) => AchievementBadge(achievement: a))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrivacySection(BuildContext context, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AppColors.info, size: 18),
              const SizedBox(width: 6),
              Text(
                AppStrings.privacyTitle,
                style: TextStyle(color: AppColors.info, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.privacyContent,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '危险区域',
            style: TextStyle(color: AppColors.danger, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmClearData(context, settings),
              icon: const Icon(Icons.delete_forever, size: 16),
              label: const Text('清除所有数据'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('确认清除数据'),
        content: const Text('此操作将删除所有时空、任务、专注记录和成就数据，且无法恢复。确定要继续吗？'),
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
                const SnackBar(
                  content: Text('所有数据已清除'),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            child: const Text('确认清除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
