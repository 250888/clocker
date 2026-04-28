class VCalculator {
  final double c;
  final Duration lookbackWindow;

  VCalculator({
    required this.c,
    this.lookbackWindow = const Duration(hours: 24),
  });

  double calculateV({
    required double focusHours,
    required double taskValue,
    required double screenPenalty,
  }) {
    double rawV = focusHours + taskValue - screenPenalty;
    return rawV.clamp(0.0, c);
  }

  double calculateVFromFocusOnly(double focusHours) {
    return focusHours.clamp(0.0, c);
  }

  double calculateVFromTasks(List<double> taskValues) {
    final total = taskValues.fold(0.0, (sum, v) => sum + v);
    return total.clamp(0.0, c);
  }

  double calculateScreenPenalty({
    required double entertainmentHours,
    required double penaltyWeight,
  }) {
    return entertainmentHours * penaltyWeight;
  }

  double calculateFocusCredit({
    required double studyAppHours,
    required double creditWeight,
  }) {
    return studyAppHours * creditWeight;
  }

  bool validateCrossCheck({
    required double focusHours,
    required double taskCompletedValue,
    required double screenStudyHours,
    double tolerance = 0.3,
  }) {
    if (focusHours <= 0) return false;
    final expectedTaskValue = focusHours * 0.5;
    final taskMatch = (taskCompletedValue - expectedTaskValue).abs() <= expectedTaskValue * (1 + tolerance);
    final screenMatch = (screenStudyHours - focusHours).abs() <= focusHours * (1 + tolerance);
    return taskMatch || screenMatch;
  }

  double enforceMaxDailyV(double rawV) {
    return rawV.clamp(0.0, c);
  }

  bool needsForcedBreak(Duration continuousFocus) {
    return continuousFocus.inMinutes >= 240;
  }

  Duration getForcedBreakDuration() {
    return const Duration(minutes: 30);
  }

  double calculateEffectiveVWithBreaks({
    required double totalFocusHours,
    required int breakCount,
  }) {
    final effectiveHours = totalFocusHours;
    return effectiveHours.clamp(0.0, c);
  }

  VCalculator copyWith({
    double? c,
    Duration? lookbackWindow,
  }) {
    return VCalculator(
      c: c ?? this.c,
      lookbackWindow: lookbackWindow ?? this.lookbackWindow,
    );
  }
}
