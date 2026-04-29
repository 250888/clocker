import 'package:flutter/material.dart';
import 'camera_service_stub.dart'
    if (dart.library.io) 'camera_service_io.dart'
    if (dart.library.html) 'camera_service_web.dart' as impl;

abstract class CameraServiceFactory {
  static CameraServiceInterface create() {
    return impl.createCameraService();
  }
}

abstract class CameraServiceInterface {
  Future<bool> initialize();
  Future<void> startCamera();
  Future<void> stopCamera();
  bool get isStreaming;
  Widget buildCameraPreview({double? width, double? height, BoxFit fit});
  void dispose();
}
