import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'web_camera_service.dart';

WebCameraService createWebCameraService() => WebCameraServiceImpl();

class WebCameraServiceImpl implements WebCameraService {
  bool _isActive = false;
  bool _isAvailable = true;
  html.VideoElement? _videoEl;
  html.MediaStream? _stream;
  bool _viewRegistered = false;
  static const String _viewType = 'clocker-camera-view';

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
        _registerView();
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

  void _registerView() {
    if (_viewRegistered || _videoEl == null) return;
    _viewRegistered = true;
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _videoEl!,
    );
  }

  Future<bool> _startCameraDirect() async {
    _videoEl?.srcObject = null;

    _videoEl = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', '')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.transform = 'scaleX(-1)'
      ..style.borderRadius = '8px';

    _registerView();

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
    _isActive = true;
    debugPrint('Web camera started via direct getUserMedia');
    return true;
  }

  @override
  void stopCamera() {
    try {
      _stream?.getTracks().forEach((t) => t.stop());
      _stream = null;
      _videoEl?.srcObject = null;
    } catch (_) {}

    _isActive = false;
  }

  @override
  void setOpacity(double opacity) {}

  @override
  void setMirror(bool mirror) {
    _videoEl?.style.transform = mirror ? 'scaleX(-1)' : 'scaleX(1)';
  }

  @override
  Widget? buildCameraPreview() {
    if (!_isActive || _videoEl == null) return null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 200,
        height: 150,
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }

  @override
  void dispose() {
    stopCamera();
  }
}
