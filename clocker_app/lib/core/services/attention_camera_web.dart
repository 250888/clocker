import 'attention_camera_interface.dart';

AttentionCameraInterface createAttentionCamera() => WebCamera();

class WebCamera implements AttentionCameraInterface {
  @override
  Future<bool> start() async => true;

  @override
  void stop() {}

  @override
  void updateAttention(double score) {}
}
