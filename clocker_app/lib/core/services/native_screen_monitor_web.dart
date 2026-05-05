import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'screen_monitor_service.dart';
import 'screen_monitor_factory.dart';

ScreenMonitorInterface createScreenMonitor() => WebScreenMonitor();

class WebScreenMonitor implements ScreenMonitorInterface {
  final ScreenMonitorService _monitor = ScreenMonitorService();
  StreamSubscription<html.Event>? _visibilitySub;
  Timer? _focusTimer;
  bool _isRunning = false;
  bool _lastVisible = true;
  int _switchCount = 0;

  @override
  void startNativeMonitoring() {
    if (_isRunning) return;
    _isRunning = true;

    _lastVisible = html.document.visibilityState == 'visible';

    _visibilitySub = html.document.onVisibilityChange.listen((_) {
      final visible = html.document.visibilityState == 'visible';
      if (visible != _lastVisible) {
        _lastVisible = visible;
        _monitor.reportPageVisibility(visible);
        if (visible) {
          _switchCount++;
          _monitor.reportForegroundApp('Browser');
          debugPrint('Web: tab visible (switch #$_switchCount)');
        } else {
          debugPrint('Web: tab hidden');
        }
      }
    });

    _focusTimer?.cancel();
    _focusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      try {
        final visible = html.document.visibilityState == 'visible';
        if (visible != _lastVisible) {
          _lastVisible = visible;
          _monitor.reportPageVisibility(visible);
          if (visible) {
            _switchCount++;
            _monitor.reportForegroundApp('Browser');
          }
        }
      } catch (_) {}
    });

    debugPrint('Web screen monitor started');
  }

  @override
  void stopNativeMonitoring() {
    _isRunning = false;
    _visibilitySub?.cancel();
    _visibilitySub = null;
    _focusTimer?.cancel();
    _focusTimer = null;
    debugPrint('Web screen monitor stopped');
  }

  @override
  void dispose() {
    stopNativeMonitoring();
  }
}
