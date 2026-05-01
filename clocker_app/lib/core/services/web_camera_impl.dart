import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart';
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
      final result = await js_util.promiseToFuture(
        js_util.callMethod(html.window, 'startCamera', []),
      );
      _isActive = result == true;
      if (_isActive) {
        setOpacity(1.0);
        setMirror(true);
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
      js_util.callMethod(html.window, 'stopCamera', []);
      _isActive = false;
      debugPrint('Web camera stopped');
    } catch (e) {
      debugPrint('Web camera stop error: $e');
    }
  }

  @override
  void setOpacity(double opacity) {
    try {
      js_util.callMethod(html.window, 'setCameraOpacity', [opacity]);
    } catch (e) {
      debugPrint('Camera opacity error: $e');
    }
  }

  @override
  void setMirror(bool mirror) {
    try {
      js_util.callMethod(html.window, 'setCameraMirror', [mirror]);
    } catch (e) {
      debugPrint('Camera mirror error: $e');
    }
  }

  @override
  void dispose() {
    stopCamera();
  }
}
