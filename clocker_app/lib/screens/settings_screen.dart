import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/achievement_provider.dart';
import '../core/engine/lorentz_engine.dart';
import '../providers/focus_provider.dart';
import '../providers/spacetime_provider.dart';
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
                        onChanged: (v) {
                          settings.setPomodoroDuration(v.toInt());
                          // 同步到专注页（空闲时立即生效，不必重启）
                          context
                              .read<FocusProvider>()
                              .setTargetDuration(Duration(minutes: v.toInt()));
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Padding(
                      padding: EdgeInsets.only(top: 6, bottom: 2),
                      child: Text(
                        '此值即「专注时空」页的默认专注时长，改完立即生效。',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 10,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _section('流 速 参 数'),
                    _sliderRow(
                      label: '惩罚基准流速 v₀',
                      value: '${settings.settings.defaultV0.toStringAsFixed(1)}×',
                      slider: Slider(
                        value: settings.settings.defaultV0.clamp(1.0, 4.0),
                        min: 1.0,
                        max: 4.0,
                        divisions: 30,
                        onChanged: (v) => settings.setDefaultV0(v),
                      ),
                    ),
                    _sliderRow(
                      label: '自律极限 c（小时/天）',
                      value: '${settings.settings.defaultC.toStringAsFixed(0)} h',
                      slider: Slider(
                        value: settings.settings.defaultC.clamp(4.0, 16.0),
                        min: 4.0,
                        max: 16.0,
                        divisions: 12,
                        onChanged: (v) => settings.setDefaultC(v),
                      ),
                    ),
                    _sliderRow(
                      label: '目标提前天数',
                      value: '${settings.settings.defaultAdvanceDays} 天',
                      slider: Slider(
                        value: settings.settings.defaultAdvanceDays
                            .clamp(1, 60)
                            .toDouble(),
                        min: 1,
                        max: 60,
                        divisions: 59,
                        onChanged: (v) =>
                            settings.setDefaultAdvanceDays(v.toInt()),
                      ),
                    ),
                    _modeRow(context, settings),
                    const SizedBox(height: 12),
                    const Text(
                      '以上为「创建自律时空」的默认值，已创建的时空不受影响。',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 10,
                        height: 1.6,
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
                    _section('专 注 统 计'),
                    _focusStats(),
                    const SizedBox(height: 22),
                    _section('时 空 道 具'),
                    _itemUsage(),
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



  /// 流速模式选择（三选一分段控件）
  Widget _modeRow(BuildContext context, SettingsProvider settings) {
    const modes = [
      (FlowMode.relativistic, '相对论'),
      (FlowMode.linear, '线性'),
      (FlowMode.exponential, '指数'),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '流速模式',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (mode, label) in modes)
                Expanded(
                  child: GestureDetector(
                    onTap: () => settings.setDefaultFlowMode(mode),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: settings.settings.defaultFlowMode == mode
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: settings.settings.defaultFlowMode == mode
                            ? Border.all(color: AppColors.primary)
                            : null,
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: settings.settings.defaultFlowMode == mode
                              ? AppColors.primary
                              : AppColors.textHint,
                          fontSize: 12,
                          fontWeight:
                              settings.settings.defaultFlowMode == mode
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '相对论 = 流速随 v 呈洛伦兹衰减；线性 / 指数为更温和的替代曲线。',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 10,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// 专注统计（真实数据：从 FocusProvider 与 SpacetimeProvider 读）
  Widget _focusStats() {
    return Consumer2<FocusProvider, SpacetimeProvider>(
      builder: (context, focus, spacetimes, _) {
        final st = spacetimes.activeSpacetime;
        final frozen = st?.isFrozen ?? false;
        final inBreak = focus.isInForceBreak;
        final continuous = focus.continuousAccrued;
        return _rowShell(
          child: Column(
            children: [
              _statRow('当前单次目标', '${focus.targetDuration.inMinutes} 分钟'),
              _statRow('本次已累计',
                  '${continuous.inMinutes} 分钟'),
              _statRow(
                '连续专注上限',
                '4 小时（触发 30 分钟强制休息）',
              ),
              _statRow(
                '强制休息',
                inBreak
                    ? '进行中 · 剩 ${focus.remainingForceBreak.inMinutes} 分钟'
                    : '未触发',
              ),
              _statRow('时空状态', frozen ? '冻结中（流速 1.0×）' : '正常计速'),
            ],
          ),
        );
      },
    );
  }

  /// 时空道具使用情况
  Widget _itemUsage() {
    return Consumer<SpacetimeProvider>(
      builder: (context, spacetimes, _) {
        final st = spacetimes.activeSpacetime;
        if (st == null) {
          return _rowShell(
            child: const Text(
              '尚未创建自律时空。',
              style: TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
          );
        }
        final cooldown = st.freezeCooldownRemaining;
        return _rowShell(
          child: Column(
            children: [
              _statRow(
                '时空冻结',
                st.isFrozen
                    ? '生效中 · 剩 ${st.freezeRemaining.inHours} 小时'
                    : (cooldown > Duration.zero
                        ? '冷却中 · ${cooldown.inDays + 1} 天后可用'
                        : '本周可用'),
              ),
              _statRow(
                '时间回溯',
                st.canRewind
                    ? '可用（任务值越高次数越多）'
                    : '次数已用完',
              ),
              _statRow(
                '已抢回天数',
                '${st.daysRecaptured.toStringAsFixed(1)} 天',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
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
