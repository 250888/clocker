import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/widgets.dart';
import 'web_camera_service.dart';

WebCameraService createWebCameraService() => WebCameraServiceImpl();

class WebCameraServiceImpl implements WebCameraService {
  bool _isActive = false;
  bool _isAvailable = true;
  html.MediaStream? _stream;

  @override
  bool get isActive => _isActive;

  @override
  bool get isAvailable => _isAvailable;

  html.VideoElement? get _video =>
      html.querySelector('#camera-video') as html.VideoElement?;
  html.DivElement? get _container =>
      html.querySelector('#camera-container') as html.DivElement?;

  @override
  Future<bool> startCamera() async {
    try {
      final video = _video;
      final container = _container;
      if (video == null || container == null) {
        debugPrint('Web camera: DOM elements not found');
        _isAvailable = false;
        return false;
      }

      final md = html.window.navigator.mediaDevices;
      if (md == null) {
        debugPrint('Web camera: mediaDevices not available');
        _isAvailable = false;
        return false;
      }

      _stream = await md.getUserMedia({
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 320},
          'height': {'ideal': 240},
        },
        'audio': false,
      });

      video.srcObject = _stream;
      video.muted = true;
      video.setAttribute('playsinline', '');
      video.setAttribute('autoplay', '');
      try {
        await video.play();
      } catch (_) {
        video.play();
      }

      container.style.display = 'block';
      container.style.zIndex = '2147483647';
      _isActive = true;
      setMirror(true);
      debugPrint('Web camera started');
      return true;
    } catch (e) {
      _isAvailable = false;
      _isActive = false;
      debugPrint('Web camera start failed: $e');
      return false;
    }
  }

  @override
  void stopCamera() {
    try {
      _stream?.getTracks().forEach((t) => t.stop());
      _stream = null;
      final container = _container;
      if (container != null) {
        container.style.display = 'none';
      }
      final video = _video;
      if (video != null) {
        video.srcObject = null;
      }
      _isActive = false;
      debugPrint('Web camera stopped');
    } catch (e) {
      debugPrint('Web camera stop error: $e');
    }
  }

  @override
  void setOpacity(double opacity) {
    final container = _container;
    if (container != null) {
      container.style.opacity = '$opacity';
    }
  }

  @override
  void setMirror(bool mirror) {
    final video = _video;
    if (video != null) {
      video.style.transform = mirror ? 'scaleX(-1)' : 'scaleX(1)';
    }
  }

  @override
  Widget? buildCameraPreview() => null;

  @override
  void dispose() {
    stopCamera();
  }
}
