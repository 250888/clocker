import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 「晨昏线」背景：冷灰天穹 + 多层彗尾星轨 + 底部燃烧的地弧。
///
/// 性能与正确性约定：
/// - 静态层（天穹/星点/地弧/雾带）与动画层（星轨）各自独立 `RepaintBoundary`，
///   动画 tick 只重绘星轨；
/// - 每层转速取**整数圈/周期**，控制器 repeat 回绕时相位连续，不会跳变；
/// - 彗尾始终朝运动反方向铺，负向层不会「尾巴跑到头前面」；
/// - 几何以「地平线在屏高 88%」为锚、半径按短边推导，宽屏不会把地弧甩出画面。
class DawnBackdrop extends StatefulWidget {
  const DawnBackdrop({super.key, this.showTrails = true});

  final bool showTrails;

  @override
  State<DawnBackdrop> createState() => _DawnBackdropState();
}

class _DawnBackdropState extends State<DawnBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _trails = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 120),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // 星轨被隐藏时不要空跑 ticker：否则每帧仍被调度，测试无法静止、真机也白耗电
    if (disabled || !widget.showTrails) {
      _trails.stop();
    } else if (!_trails.isAnimating) {
      _trails.repeat();
    }
  }

  @override
  void dispose() {
    _trails.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(
            child: CustomPaint(
              isComplex: true,
              willChange: false,
              painter: _DawnSkyPainter(),
            ),
          ),
          if (widget.showTrails)
            RepaintBoundary(
              child: CustomPaint(
                isComplex: false,
                willChange: true,
                painter: _DawnTrailPainter(_trails),
              ),
            ),
        ],
      ),
    );
  }
}

/// 一层星轨：半径系数、线宽、颜色、彗尾长度、**每周期整圈数**（决定是否无缝）。
class _TrailLayer {
  const _TrailLayer({
    required this.radiusFactor,
    required this.strokeWidth,
    required this.color,
    required this.alpha,
    required this.tail,
    required this.turns,
    required this.direction,
  });

  final double radiusFactor;
  final double strokeWidth;
  final Color color;
  final double alpha;

  /// 彗尾总弧度。
  final double tail;

  /// 每个 120s 周期转过的整圈数（整数 → 回绕无缝）。
  final int turns;
  final int direction;
}

const List<_TrailLayer> _trailLayers = [
  _TrailLayer(
    radiusFactor: 0.30,
    strokeWidth: 1.6,
    color: Color(0xFFF2EEE4),
    alpha: 0.60,
    tail: 1.35,
    turns: 1,
    direction: 1,
  ),
  _TrailLayer(
    radiusFactor: 0.42,
    strokeWidth: 1.4,
    color: Color(0xFFD8B27A),
    alpha: 0.50,
    tail: 1.15,
    turns: 2,
    direction: -1,
  ),
  _TrailLayer(
    radiusFactor: 0.54,
    strokeWidth: 1.2,
    color: Color(0xFFF2EEE4),
    alpha: 0.36,
    tail: 1.05,
    turns: 1,
    direction: 1,
  ),
  _TrailLayer(
    radiusFactor: 0.66,
    strokeWidth: 1.0,
    color: Color(0xFFC6AC86),
    alpha: 0.28,
    tail: 0.95,
    turns: 2,
    direction: -1,
  ),
  _TrailLayer(
    radiusFactor: 0.78,
    strokeWidth: 0.8,
    color: Color(0xFFF2EEE4),
    alpha: 0.20,
    tail: 0.85,
    turns: 1,
    direction: 1,
  ),
];

/// 彗尾衰减表（12 段，尾端已淡到 6%）。
const List<double> _fadeTable = [
  1.0, 0.78, 0.61, 0.47, 0.37, 0.29, 0.22, 0.17, 0.14, 0.11, 0.08, 0.06,
];

class _DawnTrailPainter extends CustomPainter {
  _DawnTrailPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = math.min(size.width, size.height);
    final pole = Offset(size.width * 0.5, size.height * 0.34);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < _trailLayers.length; i++) {
      final layer = _trailLayers[i];
      final radius = shortest * layer.radiusFactor * 1.6;
      final rect = Rect.fromCircle(center: pole, radius: radius);
      final dir = layer.direction.toDouble();
      final base = animation.value * 2 * math.pi * layer.turns * dir + i * 0.9;

      const cometCount = 2;
      for (var comet = 0; comet < cometCount; comet++) {
        final head = base + comet * math.pi;
        final steps = _fadeTable.length;
        final stepSweep = layer.tail / steps;

        for (var k = 0; k < steps; k++) {
          final fade = _fadeTable[k];
          paint
            ..strokeWidth = layer.strokeWidth * (0.55 + 0.45 * fade)
            ..color = layer.color.withValues(alpha: layer.alpha * fade * 0.85);
          // 尾巴始终在运动的反方向
          final start = head - dir * (k + 1) * stepSweep;
          canvas.drawArc(rect, start, stepSweep * 1.15, false, paint);
        }

        final headPoint = Offset(
          pole.dx + radius * math.cos(head),
          pole.dy + radius * math.sin(head),
        );
        paint
          ..style = PaintingStyle.fill
          ..color = layer.color.withValues(alpha: layer.alpha * 1.3);
        canvas.drawCircle(headPoint, layer.strokeWidth * 1.1, paint);
        paint.style = PaintingStyle.stroke;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DawnTrailPainter oldDelegate) => false;
}

class _DawnSkyPainter extends CustomPainter {
  const _DawnSkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shortest = math.min(size.width, size.height);

    // ① 冷灰天穹
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF08090B),
            Color(0xFF0A0C10),
            Color(0xFF0D0F13),
            Color(0xFF131821),
            Color(0xFF1B2130),
          ],
          stops: [0, 0.38, 0.58, 0.78, 0.95],
        ).createShader(rect),
    );

    // ② 星点（固定种子）
    final random = math.Random(42);
    final starPaint = Paint();
    for (var i = 0; i < 60; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height * 0.62;
      final r = 0.5 + random.nextDouble() * 1.1;
      starPaint.color = const Color(0xFFFFF8EA)
          .withValues(alpha: 0.12 + random.nextDouble() * 0.45);
      canvas.drawCircle(Offset(dx, dy), r, starPaint);
    }

    // ③ 天极辉光
    final pole = Offset(size.width * 0.5, size.height * 0.34);
    final poleRadius = shortest * 0.46;
    canvas.drawCircle(
      pole,
      poleRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF8F3E8).withValues(alpha: 0.07),
            const Color(0xFFD8B27A).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: pole, radius: poleRadius)),
    );

    // ④ 地弧：地平线锚定屏高 88%
    final rimY = size.height * 0.88;
    final earthRadius = math.max(shortest * 1.6, size.height * 0.5);
    final earthCenter = Offset(size.width * 0.5, rimY + earthRadius);

    canvas.drawCircle(
      earthCenter,
      earthRadius,
      Paint()..color = const Color(0xFF040405),
    );

    // 三层辉光
    final glowSpecs = <List<double>>[
      [size.height * 0.085, 0.045, 26],
      [size.height * 0.045, 0.085, 16],
      [size.height * 0.020, 0.150, 8],
    ];
    for (final spec in glowSpecs) {
      canvas.drawCircle(
        earthCenter,
        earthRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = spec[0]
          ..color = const Color(0xFFF0DFC0).withValues(alpha: spec[1])
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, spec[2]),
      );
    }

    // 大气雾带（自地弧向上淡出）
    final hazeHeight = size.height * 0.26;
    final hazeRect = Rect.fromLTWH(0, rimY - hazeHeight, size.width, hazeHeight);
    canvas.drawRect(
      hazeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFFF0DFC0).withValues(alpha: 0.16),
            const Color(0xFFD8B27A).withValues(alpha: 0.05),
            const Color(0x00D8B27A),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(hazeRect),
    );

    // 大气亮线
    canvas.drawCircle(
      earthCenter,
      earthRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = const Color(0xFFFFF8EA),
    );
    canvas.drawCircle(
      earthCenter,
      earthRadius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0x33FFF8EA)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ⑤ 顶部暗罩
    final scrimHeight = math.min(220.0, size.height * 0.26);
    final scrimRect = Rect.fromLTWH(0, 0, size.width, scrimHeight);
    canvas.drawRect(
      scrimRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE608090B), Color(0x0008090B)],
        ).createShader(scrimRect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
