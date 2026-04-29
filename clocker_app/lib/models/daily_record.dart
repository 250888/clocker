class DailyRecord {
  final String id;
  final String spacetimeId;
  final DateTime date;
  final double focusHours;
  final double taskValue;
  final double screenPenalty;
  final double vValue;
  final double flowRate;
  final int sessionsCompleted;
  final int tasksCompleted;
  final double timeEarned;
  final double timeLost;
  final bool hadFlowState;
  final Duration flowStateDuration;

  DailyRecord({
    required this.id,
    required this.spacetimeId,
    required this.date,
    this.focusHours = 0,
    this.taskValue = 0,
    this.screenPenalty = 0,
    this.vValue = 0,
    this.flowRate = 2.0,
    this.sessionsCompleted = 0,
    this.tasksCompleted = 0,
    this.timeEarned = 0,
    this.timeLost = 0,
    this.hadFlowState = false,
    this.flowStateDuration = Duration.zero,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'spacetimeId': spacetimeId,
      'date': date.toIso8601String(),
      'focusHours': focusHours,
      'taskValue': taskValue,
      'screenPenalty': screenPenalty,
      'vValue': vValue,
      'flowRate': flowRate,
      'sessionsCompleted': sessionsCompleted,
      'tasksCompleted': tasksCompleted,
      'timeEarned': timeEarned,
      'timeLost': timeLost,
      'hadFlowState': hadFlowState ? 1 : 0,
      'flowStateDurationMinutes': flowStateDuration.inMinutes,
    };
  }

  factory DailyRecord.fromMap(Map<String, dynamic> map) {
    return DailyRecord(
      id: (map['id'] ?? '') as String,
      spacetimeId: (map['spacetimeId'] ?? '') as String,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      focusHours: (map['focusHours'] as num?)?.toDouble() ?? 0.0,
      taskValue: (map['taskValue'] as num?)?.toDouble() ?? 0.0,
      screenPenalty: (map['screenPenalty'] as num?)?.toDouble() ?? 0.0,
      vValue: (map['vValue'] as num?)?.toDouble() ?? 0.0,
      flowRate: (map['flowRate'] as num?)?.toDouble() ?? 2.0,
      sessionsCompleted: (map['sessionsCompleted'] as int?) ?? 0,
      tasksCompleted: (map['tasksCompleted'] as int?) ?? 0,
      timeEarned: (map['timeEarned'] as num?)?.toDouble() ?? 0.0,
      timeLost: (map['timeLost'] as num?)?.toDouble() ?? 0.0,
      hadFlowState: (map['hadFlowState'] as int?) == 1,
      flowStateDuration:
          Duration(minutes: (map['flowStateDurationMinutes'] as int?) ?? 0),
    );
  }
}
