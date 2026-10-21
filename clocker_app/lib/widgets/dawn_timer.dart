import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/duration_formatter.dart';
import '../models/focus_session.dart';

/// 专注计时器（「晨昏线」视觉）：
/// 星轨进度盘 + 大号等宽时间 + 模式胶囊 + 单主按钮。
///
/// 接口与旧 `PomodoroTimer` 保持一致，便于直接替换。
class DawnTimer extends StatefulWidget {
  const DawnTimer({
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

  @override
  State<DawnTimer> createState() => _DawnTimerState();
}

class _DawnTimerState extends State<DawnTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 160),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  double get _progress =>
      (widget.elapsed.inSeconds / widget.target.inSeconds).clamp(0.0, 1.0);

  Duration get _remaining {
    final left = widget.target - widget.elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  String get _modeLabel {
    switch (widget.mode) {
      case FocusMode.deepFocus:
        return '深度';
      case FocusMode.study:
        return '刷题';
      case FocusMode.reading:
        return '阅读';
      case FocusMode.writing:
        return '写作';
    }
  }

  String get _statusText {
    if (!widget.isRunning) return '准 备 开 始';
    if (widget.isPaused) return '已 暂 停';
    return '专 注 中';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModeChips(),
        const SizedBox(height: 18),
        _buildDial(),
        const SizedBox(height: 26),
        _buildActions(),
      ],
    );
  }

  Widget _buildModeChips() {
    const modes = <(FocusMode, String)>[
      (FocusMode.deepFocus, '深度'),
      (FocusMode.study, '刷题'),
      (FocusMode.reading, '阅读'),
      (FocusMode.writing, '写作'),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        for (final entry in modes)
          _ModeChip(
            label: entry.$2,
            selected: widget.mode == entry.$1,
            enabled: !widget.isRunning && widget.onModeChange != null,
            onTap: widget.onModeChange,
          ),
      ],
    );
  }

  Widget _buildDial() {
    return SizedBox(
      width: 286,
      height: 286,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: const Size.square(286),
              painter: _DialPainter(
                animation: _spin,
                progress: _progress,
                active: widget.isRunning && !widget.isPaused,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DurationFormatter.formatTimerDisplay(_remaining),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 52,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusText,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 9.5,
                  letterSpacing: 3.4,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 96,
                height: 1,
                color: AppColors.hairline,
              ),
              const SizedBox(height: 10),
              Text(
                '$_modeLabel · 目标 ${widget.target.inMinutes} 分钟',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10.5,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (!widget.isRunning) {
      return SizedBox(
        width: 220,
        child: ElevatedButton(
          onPressed: widget.onStart,
          child: const Text('开始专注'),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 112,
          child: OutlinedButton(
            onPressed: widget.isPaused ? widget.onResume : widget.onPause,
            child: Text(widget.isPaused ? '继续' : '暂停'),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 148,
          child: ElevatedButton(
            onPressed: widget.onEnd,
            child: const Text('结束专注'),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color border = selected ? AppColors.primary : AppColors.hairlineStrong;
    final Color text = selected ? AppColors.primaryLight : AppColors.textHint;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 11.5,
            letterSpacing: 1.6,
          ),
        ),
      ),
    );
  }
}

/// 表盘：外层进度弧 + 三层缓慢转动的星轨 + 中心极淡辉光。
class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.animation,
    required this.progress,
    required this.active,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final double progress;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // 底环
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.hairline,
    );

    // 进度弧（香槟）
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius - 1);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = AppColors.primary,
      );
      // 弧端亮点
      final endAngle = -math.pi / 2 + 2 * math.pi * progress;
      final endPoint = Offset(
        center.dx + (radius - 1) * math.cos(endAngle),
        center.dy + (radius - 1) * math.sin(endAngle),
      );
      canvas.drawCircle(
        endPoint,
        3,
        Paint()..color = AppColors.primaryLight,
      );
    }

    // 三层星轨（虚线弧，随动画漂移）
    final phase = animation.value * 2 * math.pi;
    for (var layer = 0; layer < 3; layer++) {
      final r = radius * (0.56 + 0.13 * layer);
      final alpha = (active ? 0.30 : 0.18) - layer * 0.05;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 - layer * 0.2
        ..strokeCap = StrokeCap.round
        ..color = (layer == 1 ? AppColors.primary : AppColors.textPrimary)
            .withValues(alpha: alpha.clamp(0.05, 1.0));
      final rect = Rect.fromCircle(center: center, radius: r);
      const segments = 3;
      for (var s = 0; s < segments; s++) {
        final start =
            phase * (layer.isEven ? 1 : -1) * (1 + layer * 0.35) +
                s * (2 * math.pi / segments) +
                layer * 0.8;
        canvas.drawArc(rect, start, 0.42, false, paint);
      }
    }

    // 中心极淡辉光
    canvas.drawCircle(
      center,
      radius * 0.46,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF8F3E8).withValues(alpha: 0.05),
            const Color(0xFFD8B27A).withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius * 0.46),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.active != active;
  }
}
