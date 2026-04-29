import 'dart:io';
import 'attention_monitor_service.dart';

AttentionCameraInterface createAttentionCamera() => NativeCamera();

class NativeCamera implements AttentionCameraInterface {
  @override
  Future<bool> start() async {
    try {
      // Native platforms use simulated camera detection
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void stop() {}

  @override
  void updateAttention(double score) {}
}
