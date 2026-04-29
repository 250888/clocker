import 'package:uuid/uuid.dart';

enum FocusMode { deepFocus, study, reading, writing }
enum FocusStatus { idle, running, paused, completed, cancelled }

class FocusSession {
  final String id;
  final String spacetimeId;
  final FocusMode mode;
  final FocusStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration targetDuration;
  final Duration actualDuration;
  final double vValueEarned;
  final bool wasDistractionFree;
  final int distractionCount;
  final bool wasFlowState;
  final String? note;

  FocusSession({
    String? id,
    required this.spacetimeId,
    required this.mode,
    this.status = FocusStatus.idle,
    DateTime? startTime,
    this.endTime,
    this.targetDuration = const Duration(minutes: 25),
    this.actualDuration = Duration.zero,
    this.vValueEarned = 0,
    this.wasDistractionFree = true,
    this.distractionCount = 0,
    this.wasFlowState = false,
    this.note,
  })  : id = id ?? const Uuid().v4(),
        startTime = startTime ?? DateTime.now();

  double get focusHours => actualDuration.inMinutes / 60.0;

  bool get isCompleted => status == FocusStatus.completed;

  bool get isRunning => status == FocusStatus.running;

  bool get isPaused => status == FocusStatus.paused;

  String get modeName {
    switch (mode) {
      case FocusMode.deepFocus:
        return '深度专注';
      case FocusMode.study:
        return '刷题模式';
      case FocusMode.reading:
        return '阅读模式';
      case FocusMode.writing:
        return '写作模式';
    }
  }

  FocusSession copyWith({
    FocusMode? mode,
    FocusStatus? status,
    DateTime? endTime,
    Duration? actualDuration,
    double? vValueEarned,
    bool? wasDistractionFree,
    int? distractionCount,
    bool? wasFlowState,
    String? note,
  }) {
    return FocusSession(
      id: id,
      spacetimeId: spacetimeId,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      targetDuration: targetDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      vValueEarned: vValueEarned ?? this.vValueEarned,
      wasDistractionFree: wasDistractionFree ?? this.wasDistractionFree,
      distractionCount: distractionCount ?? this.distractionCount,
      wasFlowState: wasFlowState ?? this.wasFlowState,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'spacetimeId': spacetimeId,
      'mode': mode.index,
      'status': status.index,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'targetDurationMinutes': targetDuration.inMinutes,
      'actualDurationMinutes': actualDuration.inMinutes,
      'vValueEarned': vValueEarned,
      'wasDistractionFree': wasDistractionFree ? 1 : 0,
      'distractionCount': distractionCount,
      'wasFlowState': wasFlowState ? 1 : 0,
      'note': note,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    final modeIndex = map['mode'];
    final statusIndex = map['status'];
    return FocusSession(
      id: map['id'] as String?,
      spacetimeId: map['spacetimeId'] as String? ?? '',
      mode: FocusMode.values[(modeIndex is int ? modeIndex : 0).clamp(0, FocusMode.values.length - 1)],
      status: FocusStatus.values[(statusIndex is int ? statusIndex : 0).clamp(0, FocusStatus.values.length - 1)],
      startTime: map['startTime'] != null ? DateTime.parse(map['startTime'] as String) : DateTime.now(),
      endTime:
          map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      targetDuration: Duration(minutes: (map['targetDurationMinutes'] as num?)?.toInt() ?? 25),
      actualDuration: Duration(minutes: (map['actualDurationMinutes'] as num?)?.toInt() ?? 0),
      vValueEarned: (map['vValueEarned'] as num?)?.toDouble() ?? 0,
      wasDistractionFree: map['wasDistractionFree'] == 1,
      distractionCount: (map['distractionCount'] as num?)?.toInt() ?? 0,
      wasFlowState: map['wasFlowState'] == 1,
      note: map['note'] as String?,
    );
  }
}
