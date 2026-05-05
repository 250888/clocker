import 'dart:html' as html;
import 'package:flutter/widgets.dart';
import 'web_camera_service.dart';

WebCameraService createWebCameraService() => WebCameraServiceImpl();

class WebCameraServiceImpl implements WebCameraService {
  bool _isActive = false;
  bool _isAvailable = true;
  html.VideoElement? _videoEl;
  html.MediaStream? _stream;

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
        debugPrint('Web camera started via JS');
        return true;
      }
    } catch (e) {
      debugPrint('JS camera failed, trying direct: $e');
    }

    try {
      return await _startCameraDirect();
    } catch (e) {
      _isAvailable = false;
      debugPrint('Web camera start failed: $e');
      return false;
    }
  }

  Future<bool> _startCameraDirect() async {
    _removeExistingElements();

    final container = html.DivElement()
      ..id = 'camera-container'
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.zIndex = '2147483647'
      ..style.pointerEvents = 'none'
      ..style.overflow = 'hidden';

    _videoEl = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', '')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.transform = 'scaleX(-1)'
      ..style.display = 'none';

    container.append(_videoEl!);
    html.document.body!.append(container);

    final constraints = {
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 640},
        'height': {'ideal': 480},
      },
      'audio': false,
    };

    final stream = await html.window.navigator.mediaDevices!.getUserMedia(
      constraints,
    );
    _stream = stream;
    _videoEl!.srcObject = stream;
    _videoEl!.style.display = 'block';
    _isActive = true;
    debugPrint('Web camera started via direct getUserMedia');
    return true;
  }

  void _removeExistingElements() {
    try {
      final existing = html.document.getElementById('camera-container');
      existing?.remove();
    } catch (_) {}

    try {
      (html.window as dynamic).stopCamera();
    } catch (_) {}
  }

  @override
  void stopCamera() {
    try {
      _stream?.getTracks().forEach((t) => t.stop());
      _stream = null;
      _videoEl?.srcObject = null;
      _videoEl = null;
    } catch (_) {}

    try {
      (html.window as dynamic).stopCamera();
    } catch (_) {}

    _removeExistingElements();
    _isActive = false;
  }

  @override
  void setOpacity(double opacity) {
    try {
      (html.window as dynamic).setCameraOpacity(opacity);
    } catch (_) {}
    try {
      _videoEl?.style.opacity = '$opacity';
    } catch (_) {}
  }

  @override
  void setMirror(bool mirror) {
    try {
      (html.window as dynamic).setCameraMirror(mirror);
    } catch (_) {}
    try {
      _videoEl?.style.transform = mirror ? 'scaleX(-1)' : 'scaleX(1)';
    } catch (_) {}
  }

  @override
  Widget? buildCameraPreview() => null;

  @override
  void dispose() {
    stopCamera();
  }
}
