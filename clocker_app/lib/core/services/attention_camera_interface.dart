abstract class AttentionCameraInterface {
  Future<bool> start();
  void stop();
  void updateAttention(double score);
}
