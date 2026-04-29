import 'attention_camera_interface.dart';

AttentionCameraInterface createAttentionCamera() => StubCamera();

class StubCamera implements AttentionCameraInterface {
  @override
  Future<bool> start() async => true;

  @override
  void stop() {}

  @override
  void updateAttention(double score) {}
}
