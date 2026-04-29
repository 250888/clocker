import '../core/engine/lorentz_engine.dart';

class AppSettings {
  final double defaultV0;
  final double defaultC;
  final int defaultAdvanceDays;
  final FlowMode defaultFlowMode;
  final bool enableNotifications;
  final bool enableSoundEffects;
  final bool enableWhiteNoise;
  final bool enableScreenMonitoring;
  final bool enableCameraMonitoring;
  final bool enableMicrophoneMonitoring;
  final bool enableMotionMonitoring;
  final double screenPenaltyWeight;
  final double studyCreditWeight;
  final int pomodoroDuration;
  final int shortBreakDuration;
  final int longBreakDuration;
  final int pomodorosBeforeLongBreak;
  final bool privacyAccepted;
  final String selectedTheme;

  AppSettings({
    this.defaultV0 = 2.0,
    this.defaultC = 8.0,
    this.defaultAdvanceDays = 14,
    this.defaultFlowMode = FlowMode.relativistic,
    this.enableNotifications = true,
    this.enableSoundEffects = true,
    this.enableWhiteNoise = false,
    this.enableScreenMonitoring = false,
    this.enableCameraMonitoring = false,
    this.enableMicrophoneMonitoring = false,
    this.enableMotionMonitoring = false,
    this.screenPenaltyWeight = 1.0,
    this.studyCreditWeight = 0.8,
    this.pomodoroDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.pomodorosBeforeLongBreak = 4,
    this.privacyAccepted = false,
    this.selectedTheme = 'cosmic',
  });

  AppSettings copyWith({
    double? defaultV0,
    double? defaultC,
    int? defaultAdvanceDays,
    FlowMode? defaultFlowMode,
    bool? enableNotifications,
    bool? enableSoundEffects,
    bool? enableWhiteNoise,
    bool? enableScreenMonitoring,
    bool? enableCameraMonitoring,
    bool? enableMicrophoneMonitoring,
    bool? enableMotionMonitoring,
    double? screenPenaltyWeight,
    double? studyCreditWeight,
    int? pomodoroDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? pomodorosBeforeLongBreak,
    bool? privacyAccepted,
    String? selectedTheme,
  }) {
    return AppSettings(
      defaultV0: defaultV0 ?? this.defaultV0,
      defaultC: defaultC ?? this.defaultC,
      defaultAdvanceDays: defaultAdvanceDays ?? this.defaultAdvanceDays,
      defaultFlowMode: defaultFlowMode ?? this.defaultFlowMode,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSoundEffects: enableSoundEffects ?? this.enableSoundEffects,
      enableWhiteNoise: enableWhiteNoise ?? this.enableWhiteNoise,
      enableScreenMonitoring: enableScreenMonitoring ?? this.enableScreenMonitoring,
      enableCameraMonitoring: enableCameraMonitoring ?? this.enableCameraMonitoring,
      enableMicrophoneMonitoring: enableMicrophoneMonitoring ?? this.enableMicrophoneMonitoring,
      enableMotionMonitoring: enableMotionMonitoring ?? this.enableMotionMonitoring,
      screenPenaltyWeight: screenPenaltyWeight ?? this.screenPenaltyWeight,
      studyCreditWeight: studyCreditWeight ?? this.studyCreditWeight,
      pomodoroDuration: pomodoroDuration ?? this.pomodoroDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      pomodorosBeforeLongBreak: pomodorosBeforeLongBreak ?? this.pomodorosBeforeLongBreak,
      privacyAccepted: privacyAccepted ?? this.privacyAccepted,
      selectedTheme: selectedTheme ?? this.selectedTheme,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'defaultV0': defaultV0,
      'defaultC': defaultC,
      'defaultAdvanceDays': defaultAdvanceDays,
      'defaultFlowMode': defaultFlowMode.index,
      'enableNotifications': enableNotifications ? 1 : 0,
      'enableSoundEffects': enableSoundEffects ? 1 : 0,
      'enableWhiteNoise': enableWhiteNoise ? 1 : 0,
      'enableScreenMonitoring': enableScreenMonitoring ? 1 : 0,
      'enableCameraMonitoring': enableCameraMonitoring ? 1 : 0,
      'enableMicrophoneMonitoring': enableMicrophoneMonitoring ? 1 : 0,
      'enableMotionMonitoring': enableMotionMonitoring ? 1 : 0,
      'screenPenaltyWeight': screenPenaltyWeight,
      'studyCreditWeight': studyCreditWeight,
      'pomodoroDuration': pomodoroDuration,
      'shortBreakDuration': shortBreakDuration,
      'longBreakDuration': longBreakDuration,
      'pomodorosBeforeLongBreak': pomodorosBeforeLongBreak,
      'privacyAccepted': privacyAccepted ? 1 : 0,
      'selectedTheme': selectedTheme,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      defaultV0: (map['defaultV0'] as num?)?.toDouble() ?? 2.0,
      defaultC: (map['defaultC'] as num?)?.toDouble() ?? 8.0,
      defaultAdvanceDays: (map['defaultAdvanceDays'] as int?) ?? 14,
      defaultFlowMode: FlowMode.values[((map['defaultFlowMode'] as int?) ?? 0).clamp(0, FlowMode.values.length - 1)],
      enableNotifications: (map['enableNotifications'] as int?) == 1,
      enableSoundEffects: (map['enableSoundEffects'] as int?) == 1,
      enableWhiteNoise: (map['enableWhiteNoise'] as int?) == 1,
      enableScreenMonitoring: (map['enableScreenMonitoring'] as int?) == 1,
      enableCameraMonitoring: (map['enableCameraMonitoring'] as int?) == 1,
      enableMicrophoneMonitoring: (map['enableMicrophoneMonitoring'] as int?) == 1,
      enableMotionMonitoring: (map['enableMotionMonitoring'] as int?) == 1,
      screenPenaltyWeight: (map['screenPenaltyWeight'] as num?)?.toDouble() ?? 1.0,
      studyCreditWeight: (map['studyCreditWeight'] as num?)?.toDouble() ?? 0.8,
      pomodoroDuration: (map['pomodoroDuration'] as int?) ?? 25,
      shortBreakDuration: (map['shortBreakDuration'] as int?) ?? 5,
      longBreakDuration: (map['longBreakDuration'] as int?) ?? 15,
      pomodorosBeforeLongBreak: (map['pomodorosBeforeLongBreak'] as int?) ?? 4,
      privacyAccepted: (map['privacyAccepted'] as int?) == 1,
      selectedTheme: (map['selectedTheme'] ?? 'cosmic') as String,
    );
  }
}
