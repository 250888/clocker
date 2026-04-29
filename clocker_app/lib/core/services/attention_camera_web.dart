import 'dart:js_interop';
import 'attention_camera_interface.dart';

AttentionCameraInterface createAttentionCamera() => WebCamera();

@JS('window.clockerCamera.start')
external JSPromise _cameraStart();

@JS('window.clockerCamera.stop')
external void _cameraStop();

@JS('window.clockerCamera.setAttention')
external void _cameraSetAttention(JSNumber score);

class WebCamera implements AttentionCameraInterface {
  @override
  Future<bool> start() async {
    try {
      await _cameraStart().toDart;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void stop() {
    try {
      _cameraStop();
    } catch (e) {
      // ignore
    }
  }

  @override
  void updateAttention(double score) {
    try {
      _cameraSetAttention(score.toJS);
    } catch (e) {
      // ignore
    }
  }
}
