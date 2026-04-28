import 'dart:math';

enum FlowMode {
  relativistic,
  linear,
  exponential,
}

class LorentzEngine {
  final double v0;
  final double c;
  final FlowMode flowMode;

  LorentzEngine({
    required this.v0,
    required this.c,
    this.flowMode = FlowMode.relativistic,
  });

  double lorentzFactor(double v) {
    if (c <= 0) return 1.0;
    final clampedV = v.clamp(0.0, c * 0.9999);
    return sqrt(1 - (clampedV * clampedV) / (c * c));
  }

  double calculateFlowRate(double v) {
    final clampedV = v.clamp(0.0, c * 0.9999);
    switch (flowMode) {
      case FlowMode.relativistic:
        return v0 * lorentzFactor(clampedV);
      case FlowMode.linear:
        final ratio = clampedV / c;
        return v0 * (1 - ratio * 0.9);
      case FlowMode.exponential:
        final ratio = clampedV / c;
        return v0 * exp(-2 * ratio);
    }
  }

  double calculateAppTimeProgress(double realDaysElapsed, double v) {
    final flowRate = calculateFlowRate(v);
    return realDaysElapsed * flowRate;
  }

  double calculateAppDaysRemaining({
    required double realDaysRemaining,
    required double v,
  }) {
    final flowRate = calculateFlowRate(v);
    return realDaysRemaining * flowRate;
  }

  double calculateTimeEarned(double realHours, double v) {
    final flowRate = calculateFlowRate(v);
    final normalTime = realHours;
    final appTime = realHours * flowRate;
    return normalTime - appTime;
  }

  double calculateVFromFocusHours(double focusHours) {
    return focusHours.clamp(0.0, c);
  }

  double getFlowRatePercentage(double v) {
    final currentRate = calculateFlowRate(v);
    return (currentRate / v0).clamp(0.0, 1.0);
  }

  double getDisciplinePercentage(double v) {
    if (c <= 0) return 0.0;
    return (v / c).clamp(0.0, 1.0);
  }

  bool isInFlowState(double v, {double threshold = 0.6}) {
    return getDisciplinePercentage(v) >= threshold;
  }

  double flowStateBonus(double v) {
    if (isInFlowState(v)) {
      return calculateFlowRate(v) * 0.85;
    }
    return calculateFlowRate(v);
  }

  Map<String, dynamic> getFullMetrics(double v) {
    final flowRate = calculateFlowRate(v);
    final lorentz = lorentzFactor(v);
    final discipline = getDisciplinePercentage(v);
    final inFlow = isInFlowState(v);

    return {
      'v': v,
      'c': c,
      'v0': v0,
      'lorentzFactor': lorentz,
      'flowRate': flowRate,
      'flowRatePercentage': flowRate / v0,
      'disciplinePercentage': discipline,
      'isInFlowState': inFlow,
      'flowStateFlowRate': inFlow ? flowStateBonus(v) : flowRate,
    };
  }

  LorentzEngine copyWith({
    double? v0,
    double? c,
    FlowMode? flowMode,
  }) {
    return LorentzEngine(
      v0: v0 ?? this.v0,
      c: c ?? this.c,
      flowMode: flowMode ?? this.flowMode,
    );
  }
}
