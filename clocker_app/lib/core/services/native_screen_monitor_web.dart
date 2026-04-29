import 'package:flutter/material.dart';
import 'screen_monitor_interface.dart';

ScreenMonitorInterface createScreenMonitor() => WebScreenMonitor();

class WebScreenMonitor implements ScreenMonitorInterface {
  @override
  void startNativeMonitoring() {
    debugPrint('Web screen monitor: using Page Visibility API');
  }

  @override
  void stopNativeMonitoring() {
    debugPrint('Web screen monitor stopped');
  }

  @override
  void dispose() {}
}
