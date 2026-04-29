import 'package:uuid/uuid.dart';
import '../core/engine/lorentz_engine.dart';

class Spacetime {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime deadline;
  final double v0;
  final double c;
  final FlowMode flowMode;
  final int advanceDays;
  final bool isActive;
  final DateTime? appDeadline;
  final double totalFocusHours;
  final double totalTaskValue;
  final double totalScreenPenalty;
  final int timeFreezesUsed;
  final int timeRewindsUsed;
  final DateTime? lastFreezeTime;
  final String? emoji;

  Spacetime({
    String? id,
    required this.name,
    required this.deadline,
    this.v0 = 2.0,
    this.c = 8.0,
    this.flowMode = FlowMode.relativistic,
    this.advanceDays = 14,
    this.isActive = true,
    this.appDeadline,
    this.totalFocusHours = 0,
    this.totalTaskValue = 0,
    this.totalScreenPenalty = 0,
    this.timeFreezesUsed = 0,
    this.timeRewindsUsed = 0,
    this.lastFreezeTime,
    this.emoji,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get currentV {
    final raw = totalFocusHours + totalTaskValue - totalScreenPenalty;
    return raw.clamp(0.0, c);
  }

  int get realDaysRemaining {
    final now = DateTime.now();
    if (deadline.isBefore(now)) return 0;
    return deadline.difference(now).inDays;
  }

  double get appDaysRemaining {
    final engine = LorentzEngine(v0: v0, c: c, flowMode: flowMode);
    return engine.calculateAppDaysRemaining(
      realDaysRemaining: realDaysRemaining.toDouble(),
      v: currentV,
    );
  }

  double get currentFlowRate {
    final engine = LorentzEngine(v0: v0, c: c, flowMode: flowMode);
    return engine.calculateFlowRate(currentV);
  }

  double get disciplinePercentage {
    if (c <= 0) return 0;
    return (currentV / c).clamp(0.0, 1.0);
  }

  bool get isInFlowState {
    return disciplinePercentage >= 0.6;
  }

  double get timeEarned {
    final engine = LorentzEngine(v0: v0, c: c, flowMode: flowMode);
    return engine.calculateTimeEarned(realDaysRemaining.toDouble(), currentV);
  }

  bool get canFreeze {
    final now = DateTime.now();
    if (lastFreezeTime != null) {
      final daysSinceLastFreeze = now.difference(lastFreezeTime!).inDays;
      if (daysSinceLastFreeze < 7) return false;
    }
    return timeFreezesUsed < 1;
  }

  Spacetime copyWith({
    String? name,
    DateTime? deadline,
    double? v0,
    double? c,
    FlowMode? flowMode,
    int? advanceDays,
    bool? isActive,
    DateTime? appDeadline,
    double? totalFocusHours,
    double? totalTaskValue,
    double? totalScreenPenalty,
    int? timeFreezesUsed,
    int? timeRewindsUsed,
    DateTime? lastFreezeTime,
    String? emoji,
  }) {
    return Spacetime(
      id: id,
      name: name ?? this.name,
      deadline: deadline ?? this.deadline,
      v0: v0 ?? this.v0,
      c: c ?? this.c,
      flowMode: flowMode ?? this.flowMode,
      advanceDays: advanceDays ?? this.advanceDays,
      isActive: isActive ?? this.isActive,
      appDeadline: appDeadline ?? this.appDeadline,
      totalFocusHours: totalFocusHours ?? this.totalFocusHours,
      totalTaskValue: totalTaskValue ?? this.totalTaskValue,
      totalScreenPenalty: totalScreenPenalty ?? this.totalScreenPenalty,
      timeFreezesUsed: timeFreezesUsed ?? this.timeFreezesUsed,
      timeRewindsUsed: timeRewindsUsed ?? this.timeRewindsUsed,
      lastFreezeTime: lastFreezeTime ?? this.lastFreezeTime,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'v0': v0,
      'c': c,
      'flowMode': flowMode.index,
      'advanceDays': advanceDays,
      'isActive': isActive ? 1 : 0,
      'appDeadline': appDeadline?.toIso8601String(),
      'totalFocusHours': totalFocusHours,
      'totalTaskValue': totalTaskValue,
      'totalScreenPenalty': totalScreenPenalty,
      'timeFreezesUsed': timeFreezesUsed,
      'timeRewindsUsed': timeRewindsUsed,
      'lastFreezeTime': lastFreezeTime?.toIso8601String(),
      'emoji': emoji,
    };
  }

  factory Spacetime.fromMap(Map<String, dynamic> map) {
    final flowModeIndex = map['flowMode'];
    final flowMode = FlowMode.values[(flowModeIndex is int ? flowModeIndex : 0).clamp(0, FlowMode.values.length - 1)];
    return Spacetime(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline'] as String) : DateTime.now().add(const Duration(days: 30)),
      v0: (map['v0'] as num?)?.toDouble() ?? 2.0,
      c: (map['c'] as num?)?.toDouble() ?? 8.0,
      flowMode: flowMode,
      advanceDays: (map['advanceDays'] as num?)?.toInt() ?? 14,
      isActive: map['isActive'] == 1,
      appDeadline: map['appDeadline'] != null
          ? DateTime.parse(map['appDeadline'] as String)
          : null,
      totalFocusHours: (map['totalFocusHours'] as num?)?.toDouble() ?? 0,
      totalTaskValue: (map['totalTaskValue'] as num?)?.toDouble() ?? 0,
      totalScreenPenalty: (map['totalScreenPenalty'] as num?)?.toDouble() ?? 0,
      timeFreezesUsed: (map['timeFreezesUsed'] as num?)?.toInt() ?? 0,
      timeRewindsUsed: (map['timeRewindsUsed'] as num?)?.toInt() ?? 0,
      lastFreezeTime: map['lastFreezeTime'] != null
          ? DateTime.parse(map['lastFreezeTime'] as String)
          : null,
      emoji: map['emoji'] as String?,
    );
  }
}
