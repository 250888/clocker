import 'dart:html' as html;
import 'package:flutter/widgets.dart';
import 'web_camera_service.dart';

WebCameraService createWebCameraService() => WebCameraServiceImpl();

class WebCameraServiceImpl implements WebCameraService {
  bool _isActive = false;
  bool _isAvailable = true;

  @override
  bool get isActive => _isActive;

  @override
  bool get isAvailable => _isAvailable;

  @override
  Future<bool> startCamera() async {
    try {
      final result = await (html.window as dynamic).startCamera();
      _isActive = result == true;
      if (_isActive) {
        debugPrint('Web camera started');
      }
      return _isActive;
    } catch (e) {
      _isAvailable = false;
      debugPrint('Web camera start failed: $e');
      return false;
    }
  }

  @override
  void stopCamera() {
    try {
      (html.window as dynamic).stopCamera();
      _isActive = false;
      debugPrint('Web camera stopped');
    } catch (e) {
      debugPrint('Web camera stop error: $e');
    }
  }

  @override
  void setOpacity(double opacity) {
    try {
      (html.window as dynamic).setCameraOpacity(opacity);
    } catch (e) {
      debugPrint('Camera opacity error: $e');
    }
  }

  @override
  void setMirror(bool mirror) {
    try {
      (html.window as dynamic).setCameraMirror(mirror);
    } catch (e) {
      debugPrint('Camera mirror error: $e');
    }
  }

  @override
  Widget? buildCameraPreview() => null;

  @override
  void dispose() {
    stopCamera();
  }
}
