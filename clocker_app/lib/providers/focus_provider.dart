import 'dart:async';
import 'package:flutter/material.dart';
import '../models/focus_session.dart';
import '../core/utils/database_factory.dart';
import '../core/services/audio_service.dart';
import '../core/services/screen_monitor_service.dart';
import '../core/services/screen_monitor_factory.dart';
import '../core/services/attention_monitor_service.dart';
import '../core/services/web_camera_service.dart';

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

  final AudioService _audioService = AudioService();
  final ScreenMonitorService _screenMonitor = ScreenMonitorService();
  final AttentionMonitorService _attentionMonitor = AttentionMonitorService();
  final WebCameraService _cameraService = WebCameraService.instance;
  ScreenMonitorInterface? _nativeMonitor;

  bool _enableWhiteNoise = true;
  bool _enableScreenMonitoring = true;
  bool _enableAttentionMonitoring = true;
  bool _enableCamera = true;
  String _selectedNoise = 'rain';

  FocusSession? get currentSession => _currentSession;
  Duration get elapsed => _elapsed;
  Duration get targetDuration => _targetDuration;
  FocusMode get selectedMode => _selectedMode;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get distractionCount => _distractionCount;
  Duration get remaining {
    final r = _targetDuration - _elapsed;
    return r.isNegative ? Duration.zero : r;
  }

  double get progress {
    if (_targetDuration.inSeconds <= 0) return 0.0;
    return (_elapsed.inSeconds / _targetDuration.inSeconds).clamp(0.0, 1.0);
  }

  AudioService get audioService => _audioService;
  ScreenMonitorService get screenMonitor => _screenMonitor;
  AttentionMonitorService get attentionMonitor => _attentionMonitor;
  WebCameraService get cameraService => _cameraService;

  bool get enableWhiteNoise => _enableWhiteNoise;
  bool get enableScreenMonitoring => _enableScreenMonitoring;
  bool get enableAttentionMonitoring => _enableAttentionMonitoring;
  bool get enableCamera => _enableCamera;
  String get selectedNoise => _selectedNoise;
  double get volume => _audioService.volume;
  bool get isCameraActive => _cameraService.isActive;

  void setMode(FocusMode mode) {
    _selectedMode = mode;
    notifyListeners();
  }

  void setTargetDuration(Duration duration) {
    _targetDuration = duration;
    notifyListeners();
  }

  void configure({
    bool? enableWhiteNoise,
    bool? enableScreenMonitoring,
    bool? enableAttentionMonitoring,
    bool? enableCamera,
    String? selectedNoise,
  }) {
    if (enableWhiteNoise != null) _enableWhiteNoise = enableWhiteNoise;
    if (enableScreenMonitoring != null) {
      _enableScreenMonitoring = enableScreenMonitoring;
    }
    if (enableAttentionMonitoring != null) {
      _enableAttentionMonitoring = enableAttentionMonitoring;
    }
    if (enableCamera != null) _enableCamera = enableCamera;
    if (selectedNoise != null) _selectedNoise = selectedNoise;
    notifyListeners();
  }

  void startFocus(String spacetimeId) {
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

    _startServices();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();

      if (_elapsed >= _targetDuration) {
        completeFocus();
      }
    });

    notifyListeners();
  }

  Future<void> _startServices() async {
    try {
      if (_enableWhiteNoise) {
        try {
          await _audioService.ensureInitialized();
          await _audioService.playWhiteNoise(_selectedNoise, volume: 0.5);
        } catch (e) {
          debugPrint('White noise error: $e');
        }
      }

      if (_enableScreenMonitoring) {
        try {
          _screenMonitor.startMonitoring();
          _nativeMonitor = ScreenMonitorFactory.create();
          _nativeMonitor!.startNativeMonitoring();
        } catch (e) {
          debugPrint('Screen monitor error: $e');
        }
      }

      if (_enableAttentionMonitoring) {
        try {
          _attentionMonitor.initialize();
          _attentionMonitor.startMonitoring();
        } catch (e) {
          debugPrint('Attention monitor error: $e');
        }
      }

      if (_enableCamera) {
        try {
          await _cameraService.startCamera();
          notifyListeners();
        } catch (e) {
          debugPrint('Camera error: $e');
        }
      }
    } catch (e) {
      debugPrint('Service startup error: $e');
    }
  }

  void _stopServices() {
    _screenMonitor.stopMonitoring();
    _nativeMonitor?.stopNativeMonitoring();
    _attentionMonitor.stopMonitoring();
    _cameraService.stopCamera();
  }

  void pauseFocus() {
    if (!_isRunning || _isPaused) return;
    _timer?.cancel();
    _isPaused = true;

    try {
      _audioService.stopWhiteNoise();
      _attentionMonitor.stopMonitoring();
    } catch (e) {
      debugPrint('Pause error: $e');
    }

    notifyListeners();
  }

  void resumeFocus() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;

    try {
      if (_enableWhiteNoise) {
        _audioService.playWhiteNoise(_selectedNoise, volume: 0.5);
      }
      if (_enableAttentionMonitoring) {
        _attentionMonitor.startMonitoring();
      }
    } catch (e) {
      debugPrint('Resume error: $e');
    }

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
    if (!_isRunning) return;
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;

    try {
      if (_currentSession != null) {
        final attentionDistractions = _enableAttentionMonitoring
            ? _attentionMonitor.distractionEvents
            : 0;
        final wasFlow =
            _enableAttentionMonitoring &&
            (_attentionMonitor.isInFlowState || _elapsed.inMinutes >= 30);

        final completed = _currentSession!.copyWith(
          status: FocusStatus.completed,
          endTime: DateTime.now(),
          actualDuration: _elapsed,
          vValueEarned: _elapsed.inMinutes / 60.0,
          distractionCount: _distractionCount + attentionDistractions,
          wasDistractionFree:
              _distractionCount == 0 && attentionDistractions == 0,
          wasFlowState: wasFlow,
        );
        await _db.insertFocusSession(completed);
        _currentSession = completed;

        try {
          await _audioService.playCompletionSound();
        } catch (e) {
          debugPrint('Completion sound error: $e');
        }
      }
    } catch (e) {
      debugPrint('Complete focus error: $e');
    }

    try {
      _audioService.stopWhiteNoise();
      _stopServices();
    } catch (e) {
      debugPrint('Stop services error: $e');
    }

    notifyListeners();
  }

  Future<void> cancelFocus() async {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;

    _audioService.stopWhiteNoise();
    _stopServices();

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
    _audioService.playDistractionSound();
    notifyListeners();
  }

  void adjustVolume(double volume) {
    _audioService.setVolume(volume);
    notifyListeners();
  }

  Future<List<FocusSession>> getFocusHistory(String spacetimeId) async {
    return await _db.getFocusSessionsForSpacetime(spacetimeId);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.stopWhiteNoise();
    _stopServices();
    _nativeMonitor?.dispose();
    _audioService.dispose();
    super.dispose();
  }
}
