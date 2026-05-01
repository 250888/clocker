import 'web_camera_service.dart';

WebCameraService createWebCameraService() => _StubCameraService();

class _StubCameraService implements WebCameraService {
  @override
  bool get isActive => false;

  @override
  bool get isAvailable => false;

  @override
  Future<bool> startCamera() async => false;

  @override
  void stopCamera() {}

  @override
  void setOpacity(double opacity) {}

  @override
  void setMirror(bool mirror) {}

  @override
  void dispose() {}
}
