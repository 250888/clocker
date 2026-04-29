import 'screen_monitor_interface.dart';

ScreenMonitorInterface createScreenMonitor() => StubScreenMonitor();

class StubScreenMonitor implements ScreenMonitorInterface {
  @override
  void startNativeMonitoring() {}

  @override
  void stopNativeMonitoring() {}

  @override
  void dispose() {}
}
