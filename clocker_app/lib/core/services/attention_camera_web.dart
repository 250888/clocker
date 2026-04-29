import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'attention_monitor_service.dart';

AttentionCameraInterface createAttentionCamera() => WebCamera();

class WebCamera implements AttentionCameraInterface {
  @override
  Future<bool> start() async {
    try {
      final camera = web.window.getProperty('clockerCamera'.toJS);
      if (camera == null) return false;
      final startFn = camera.getProperty('start'.toJS);
      if (startFn == null) return false;
      await (startFn.callMethod0() as JSPromise).toDart;
      final isRunning = camera.getProperty('isRunning'.toJS) as JSBoolean;
      return isRunning.toDart;
    } catch (e) {
      return false;
    }
  }

  @override
  void stop() {
    try {
      final camera = web.window.getProperty('clockerCamera'.toJS);
      if (camera != null) {
        final stopFn = camera.getProperty('stop'.toJS);
        stopFn?.callMethod0();
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void updateAttention(double score) {
    try {
      final camera = web.window.getProperty('clockerCamera'.toJS);
      if (camera != null) {
        final setAttnFn = camera.getProperty('setAttention'.toJS);
        setAttnFn?.callMethod1(score.toJS);
      }
    } catch (e) {
      // ignore
    }
  }
}
