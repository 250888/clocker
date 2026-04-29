import 'dart:async';
import 'package:flutter/material.dart';
import '../models/focus_session.dart';
import '../core/utils/database_factory.dart';

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

  FocusSession? get currentSession => _currentSession;
  Duration get elapsed => _elapsed;
  Duration get targetDuration => _targetDuration;
  FocusMode get selectedMode => _selectedMode;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get distractionCount => _distractionCount;
  Duration get remaining => _targetDuration - _elapsed;
  double get progress => _elapsed.inSeconds / _targetDuration.inSeconds;

  void setMode(FocusMode mode) {
    _selectedMode = mode;
    notifyListeners();
  }

  void setTargetDuration(Duration duration) {
    _targetDuration = duration;
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

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
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
    notifyListeners();
  }

  void resumeFocus() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
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

    if (_currentSession != null) {
      final completed = _currentSession!.copyWith(
        status: FocusStatus.completed,
        endTime: DateTime.now(),
        actualDuration: _elapsed,
        vValueEarned: _elapsed.inMinutes / 60.0,
        distractionCount: _distractionCount,
        wasDistractionFree: _distractionCount == 0,
        wasFlowState: _elapsed.inMinutes >= 30,
      );
      await _db.insertFocusSession(completed);
      _currentSession = completed;
    }

    notifyListeners();
  }

  Future<void> cancelFocus() async {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;

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
    notifyListeners();
  }

  Future<List<FocusSession>> getFocusHistory(String spacetimeId) async {
    return await _db.getFocusSessionsForSpacetime(spacetimeId);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
