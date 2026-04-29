import 'screen_monitor_stub.dart'
    if (dart.library.io) 'native_screen_monitor_io.dart'
    if (dart.library.html) 'native_screen_monitor_web.dart' as impl;

abstract class ScreenMonitorFactory {
  static ScreenMonitorInterface create() {
    return impl.createScreenMonitor();
  }
}

abstract class ScreenMonitorInterface {
  void startNativeMonitoring();
  void stopNativeMonitoring();
  void dispose();
}
