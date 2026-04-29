import 'dart:async';
import 'package:flutter/material.dart';
import '../models/focus_session.dart';
import '../core/utils/database_factory.dart';
import '../core/services/audio_service.dart';
import '../core/services/screen_monitor_service.dart';
import '../core/services/screen_monitor_factory.dart';
import '../core/services/screen_monitor_interface.dart';
import '../core/services/attention_monitor_service.dart';

class FocusProvider extends ChangeNotifier {
  FocusSession? _currentSession;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  Duration _targetDuration = const Duration(minutes: 25);
  FocusMode _selectedMode = FocusMode.deepFocus;
  bool _isRunning = false;
  bool _isPaused = false;
  int _distractionCount = 0;
  final DatabaseHelperInterface _db = DatabaseFactory.create();

  final AudioService _audio = AudioService();
  final ScreenMonitorService _screenMonitor = ScreenMonitorService();
  final AttentionMonitorService _attentionMonitor = AttentionMonitorService();
  ScreenMonitorInterface? _nativeMonitor;

  bool _enableSoundEffects = false;
  bool _enableWhiteNoise = false;
  bool _enableScreenMonitoring = false;
  bool _enableAttentionMonitoring = false;
  String _whiteNoiseType = 'rain';

  FocusSession? get currentSession => _currentSession;
  Duration get elapsed => _elapsed;
  Duration get targetDuration => _targetDuration;
  FocusMode get selectedMode => _selectedMode;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get distractionCount => _distractionCount;
  Duration get remaining => _targetDuration - _elapsed;
  double get progress => _targetDuration.inSeconds > 0
      ? _elapsed.inSeconds / _targetDuration.inSeconds
      : 0.0;

  AudioService get audio => _audio;
  ScreenMonitorService get screenMonitor => _screenMonitor;
  AttentionMonitorService get attentionMonitor => _attentionMonitor;

  bool get enableSoundEffects => _enableSoundEffects;
  bool get enableWhiteNoise => _enableWhiteNoise;
  bool get enableScreenMonitoring => _enableScreenMonitoring;
  bool get enableAttentionMonitoring => _enableAttentionMonitoring;
  String get whiteNoiseType => _whiteNoiseType;

  void configure({
    bool? soundEffects,
    bool? whiteNoise,
    bool? screenMonitoring,
    bool? attentionMonitoring,
    String? noiseType,
  }) {
    if (soundEffects != null) _enableSoundEffects = soundEffects;
    if (whiteNoise != null) _enableWhiteNoise = whiteNoise;
    if (screenMonitoring != null) _enableScreenMonitoring = screenMonitoring;
    if (attentionMonitoring != null) _enableAttentionMonitoring = attentionMonitoring;
    if (noiseType != null) _whiteNoiseType = noiseType;
  }

  void setMode(FocusMode mode) {
    _selectedMode = mode;
    notifyListeners();
  }

  void setTargetDuration(Duration duration) {
    _targetDuration = duration;
    notifyListeners();
  }

  void startFocus(String spacetimeId, {double flowRate = 1.0}) {
    _currentSession = FocusSession(
      spacetimeId: spacetimeId,
      mode: _selectedMode,
      status: FocusStatus.running,
      targetDuration: _targetDuration,
    );
    _elapsed = Duration.zero;
    _isRunning = true;
    _isPaused = false;
    _distractionCount = 0;

    if (_enableWhiteNoise) {
      _audio.playWhiteNoise(_whiteNoiseType);
      _audio.adjustToFlowRate(flowRate);
    }

    if (_enableScreenMonitoring) {
      _screenMonitor.startMonitoring();
      try {
        _nativeMonitor = ScreenMonitorFactory.create();
        _nativeMonitor!.startNativeMonitoring();
      } catch (e) {
        debugPrint('Native monitor error: $e');
      }
    }

    if (_enableAttentionMonitoring) {
      _attentionMonitor.startMonitoring();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);

      if (_enableSoundEffects && _elapsed.inSeconds > 0 && _elapsed.inSeconds % 60 == 0) {
        _audio.playTickSound();
      }

      if (_enableAttentionMonitoring && _elapsed.inSeconds > 0 && _elapsed.inSeconds % 30 == 0) {
        final score = _attentionMonitor.attentionScore;
        if (score < 0.4) {
          _distractionCount++;
          if (_enableSoundEffects) _audio.playDistractionSound();
        }
      }

      if (_enableWhiteNoise && _elapsed.inSeconds > 0 && _elapsed.inSeconds % 60 == 0) {
        _audio.adjustToFlowRate(flowRate);
      }

      notifyListeners();

      if (_elapsed >= _targetDuration) {
        completeFocus();
      }
    });

    notifyListeners();
  }

  void pauseFocus() {
    if (!_isRunning || _isPaused) return;
    _timer?.cancel();
    _isPaused = true;

    if (_enableScreenMonitoring) _screenMonitor.stopMonitoring();
    _nativeMonitor?.stopNativeMonitoring();
    if (_enableAttentionMonitoring) _attentionMonitor.stopMonitoring();

    notifyListeners();
  }

  void resumeFocus() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;

    if (_enableScreenMonitoring) _screenMonitor.startMonitoring();
    if (_nativeMonitor != null) {
      _nativeMonitor!.startNativeMonitoring();
    }
    if (_enableAttentionMonitoring) _attentionMonitor.startMonitoring();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();

      if (_elapsed >= _targetDuration) {
        completeFocus();
      }
    });
    notifyListeners();
  }

  Future<void> completeFocus() async {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;

    _audio.stopWhiteNoise();
    _screenMonitor.stopMonitoring();
    _nativeMonitor?.stopNativeMonitoring();
    _nativeMonitor?.dispose();
    _nativeMonitor = null;
    _attentionMonitor.stopMonitoring();

    final wasFlowState = _attentionMonitor.isInFlowState || _elapsed.inMinutes >= 30;

    if (_currentSession != null) {
      final completed = _currentSession!.copyWith(
        status: FocusStatus.completed,
        endTime: DateTime.now(),
        actualDuration: _elapsed,
        vValueEarned: _elapsed.inMinutes / 60.0,
        distractionCount: _distractionCount,
        wasDistractionFree: _distractionCount == 0,
        wasFlowState: wasFlowState,
      );
      await _db.insertFocusSession(completed);
      _currentSession = completed;
    }

    if (_enableSoundEffects) {
      _audio.playCompletionSound();
    }

    notifyListeners();
  }

  Future<void> cancelFocus() async {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;

    _audio.stopWhiteNoise();
    _screenMonitor.stopMonitoring();
    _nativeMonitor?.stopNativeMonitoring();
    _nativeMonitor?.dispose();
    _nativeMonitor = null;
    _attentionMonitor.stopMonitoring();

    if (_currentSession != null) {
      final cancelled = _currentSession!.copyWith(
        status: FocusStatus.cancelled,
        endTime: DateTime.now(),
        actualDuration: _elapsed,
        distractionCount: _distractionCount,
      );
      await _db.insertFocusSession(cancelled);
    }

    _currentSession = null;
    _elapsed = Duration.zero;
    notifyListeners();
  }

  void recordDistraction() {
    _distractionCount++;
    _attentionMonitor.reportDistraction();
    if (_enableSoundEffects) _audio.playDistractionSound();
    notifyListeners();
  }

  Future<List<FocusSession>> getFocusHistory(String spacetimeId) async {
    return await _db.getFocusSessionsForSpacetime(spacetimeId);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audio.dispose();
    _nativeMonitor?.dispose();
    super.dispose();
  }
}
