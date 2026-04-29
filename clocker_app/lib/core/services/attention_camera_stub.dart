import 'attention_camera_io.dart'
    if (dart.library.html) 'attention_camera_web.dart'
    if (dart.library.io) 'attention_camera_io.dart' as impl;

import 'attention_monitor_service.dart';

AttentionCameraInterface createAttentionCamera() => impl.createAttentionCamera();

abstract class AttentionCameraInterface {
  Future<bool> start();
  void stop();
  void updateAttention(double score);
}
