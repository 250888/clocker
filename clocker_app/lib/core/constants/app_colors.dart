import 'package:flutter/material.dart';

/// Clocker 调色板 · 「晨昏线」冷灰中性 + 香槟强调
///
/// 设计原则（2026-10 定案）：
/// - 底色是**冷灰中性黑**（不是蓝黑、不是棕黑），接近真空里的暗面；
/// - 全局只有**一种彩色**：低饱和香槟金 `0xFFD8B27A`，只给「行动 / 数据高亮 / 选中态」；
/// - 文字全部走象牙-灰阶四级，禁止彩色正文；
/// - 状态色去饱和（成功=灰绿、警告=赭、危险=暗红），避免「AI 配色」的荧光感；
/// - 渐变只用于星图/成就等氛围处，且限定在香槟-褐的同一色温内。
class AppColors {
  // ── 强调色（全球唯一彩色）──────────────────────────────
  static const Color primary = Color(0xFFD8B27A); // 香槟金
  static const Color primaryDark = Color(0xFFB08F5C);
  static const Color primaryLight = Color(0xFFF0DFC0);

  // ── 次级强调（极淡沙色，用于次高亮）────────────────────
  static const Color accent = Color(0xFFE6D9BE);
  static const Color accentDark = Color(0xFFB9A27C);

  // ── 表面（四级色阶做层级，不靠阴影）────────────────────
  static const Color background = Color(0xFF08090B); // void
  static const Color surface = Color(0xFF0E1013); // surface-1
  static const Color surfaceLight = Color(0xFF14171C); // surface-2
  static const Color card = Color(0xFF12151A); // 卡片

  // ── 文字（灰阶四级）──────────────────────────────────
  static const Color textPrimary = Color(0xFFF2EEE4); // 象牙
  static const Color textSecondary = Color(0xFFB9B6AE);
  static const Color textHint = Color(0xFF9EA0A6); // 4.9:1 on surface, 抗雾带衰减

  // ── 状态（全部去饱和）────────────────────────────────
  static const Color success = Color(0xFF7FA980); // 灰绿
  static const Color warning = Color(0xFFC2A05E); // 赭
  static const Color danger = Color(0xFFD2695D); // 暗红，文字版 ≥4.5:1
  static const Color info = Color(0xFF7E97A8); // 钢蓝灰

  // ── 流速语义：慢→快 的冷暖过渡 ───────────────────────
  static const Color flowSlow = Color(0xFF7FA980); // 钟慢
  static const Color flowMedium = Color(0xFFC2A05E);
  static const Color flowFast = Color(0xFFC2554B); // 钟快

  // ── 星图 / 氛围（限定香槟-褐色温）────────────────────
  static const Color cosmic1 = Color(0xFFF0DFC0);
  static const Color cosmic2 = Color(0xFFD8B27A);
  static const Color cosmic3 = Color(0xFF8A6A45);
  static const Color cosmic4 = Color(0xFFB08F5C); // 仅氛围用途，不再做文字色

  static const Color starWhite = Color(0xFFFFF8EA);

  // ── 渐变 ────────────────────────────────────────────
  static const LinearGradient cosmicGradient = LinearGradient(
        colors: [cosmic1, cosmic2, cosmic3],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static const LinearGradient flowRateGradient = LinearGradient(
        colors: [flowSlow, flowMedium, flowFast],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static const LinearGradient cardGradient = LinearGradient(
        colors: [surface, surfaceLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// 主屏「晨昏线」地弧光晕：一线暖白 → 暗面
  static const LinearGradient dawnLimbGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF8EA), // 大气亮线
      Color(0x66F0DFC0), // 上层散射
      Color(0x1AA8784E), // 低饱和铜棕
      Color(0x00040505), // 暗面
    ],
    stops: [0.0, 0.10, 0.34, 1.0],
  );

  /// 1px 发丝线
  static const Color hairline = Color(0xFF22252B);
  static const Color hairlineStrong = Color(0xFF343842);
}
