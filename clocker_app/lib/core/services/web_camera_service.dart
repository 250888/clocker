import 'dart:async';
import 'web_camera_impl.dart'
    if (dart.library.io) 'web_camera_stub.dart'
    as impl;

abstract class WebCameraService {
  static final WebCameraService _instance = impl.createWebCameraService();
  static WebCameraService get instance => _instance;

  bool get isActive;
  bool get isAvailable;

  Future<bool> startCamera();
  void stopCamera();
  void setOpacity(double opacity);
  void setMirror(bool mirror);
  void dispose();
}
