import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/spacetime.dart';

/// 首页「时空仪表盘」主视觉：现实剩余天数 + 流速卡 + 盈亏行。
///
/// 只负责呈现 `Spacetime` 的既有派生字段，不引入新状态。
class DawnDashboardHero extends StatelessWidget {
  const DawnDashboardHero({super.key, required this.spacetime});

  final Spacetime spacetime;

  String _fmtDays(double days) {
    if (days.abs() >= 100) return days.round().toString();
    return days.toStringAsFixed(1);
  }

  double get _ratio {
    final c = spacetime.c == 0 ? 1 : spacetime.c;
    return (spacetime.currentV / c).clamp(0.0, 1.0);
  }

  /// γ = 1/√(1−(v/c)²)；接近上限时不再显示夸张数字。
  String get _gammaLabel {
    final r = _ratio.clamp(0.0, 0.99995);
    final gamma = 1 / math.sqrt(1 - r * r);
    return gamma > 20 ? 'γ > 20' : 'γ ${gamma.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final inFlow = spacetime.isInFlowState;
    final frozen = spacetime.isFrozen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '现 实 剩 余',
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 10,
            letterSpacing: 3.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${spacetime.realDaysRemaining}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 62,
                fontWeight: FontWeight.w300,
                height: 1,
                letterSpacing: -2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 10),
              child: Text(
                '天',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 右侧读数在窄屏下可收缩，避免溢出
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'APP 内 ${_fmtDays(spacetime.effectiveAppDaysRemaining)} 天',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '按当前流速推算 · 截止 ${spacetime.deadline.month}/${spacetime.deadline.day}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _Delta(
              label: '已赚',
              value: '+${_fmtDays(spacetime.timeEarnedDays)} 天',
              color: AppColors.success,
            ),
            const SizedBox(width: 18),
            _Delta(
              label: '已损',
              value: '−${_fmtDays(spacetime.timeLostDays)} 天',
              color: AppColors.danger,
            ),
            const SizedBox(width: 18),
            _Delta(
              label: '已抢回',
              value: '${_fmtDays(spacetime.daysRecaptured)} 天',
              color: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
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
                    '当 前 流 速',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 10,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const Spacer(),
                  if (frozen)
                    _StatusChip(
                      text: '冻结中 ${spacetime.freezeRemaining.inHours}h'
                          '${spacetime.canFreeze ? '' : ' · 冷却 ${spacetime.freezeCooldownRemaining.inDays + 1}d'}',
                      color: AppColors.primaryLight,
                    )
                  else if (inFlow)
                    const _StatusChip(text: '心流中'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${spacetime.effectiveFlowRate.toStringAsFixed(2)}×',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.5,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '自律 ${spacetime.currentV.toStringAsFixed(1)}'
                      ' / ${spacetime.c.toStringAsFixed(1)} h · $_gammaLabel',
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 10.5,
                        letterSpacing: 0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: spacetime.disciplinePercentage.clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    '钟慢',
                    style: TextStyle(color: AppColors.textHint, fontSize: 9.5),
                  ),
                  Spacer(),
                  Text(
                    '自律极限',
                    style: TextStyle(color: AppColors.textHint, fontSize: 9.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textHint, fontSize: 10),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(color: c, fontSize: 9.5, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}
