import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'camera_service_factory.dart';

CameraServiceInterface createCameraService() => WebCameraService();

class WebCameraService implements CameraServiceInterface {
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  bool _isStreaming = false;
  bool _initialized = false;
  bool _viewFactoryRegistered = false;
  String _viewId = 'clocker-camera-${DateTime.now().millisecondsSinceEpoch}';

  @override
  bool get isStreaming => _isStreaming;

  @override
  Future<bool> initialize() async {
    try {
      _videoElement = html.VideoElement()
        ..id = _viewId
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.transform = 'scaleX(-1)'
        ..setAttribute('playsinline', '');

      _registerViewFactory();
      _initialized = true;
      debugPrint('Web camera service initialized');
      return true;
    } catch (e) {
      debugPrint('Web camera init error: $e');
      return false;
    }
  }

  void _registerViewFactory() {
    if (_viewFactoryRegistered) return;
    _viewFactoryRegistered = true;

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..style.borderRadius = '12px';

      if (_videoElement != null) {
        container.append(_videoElement!);
      }

      return container;
    });
  }

  @override
  Future<void> startCamera() async {
    if (!_initialized || _isStreaming) return;

    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        debugPrint('MediaDevices not available');
        return;
      }

      final constraints = {
        'video': {
          'width': {'ideal': 320},
          'height': {'ideal': 240},
          'facingMode': 'user',
        },
        'audio': false,
      };

      _mediaStream = await mediaDevices.getUserMedia(constraints);
      _videoElement!.srcObject = _mediaStream;
      _isStreaming = true;
      debugPrint('Web camera started');
    } catch (e) {
      debugPrint('Web camera start error: $e');
    }
  }

  @override
  Future<void> stopCamera() async {
    if (!_isStreaming) return;

    try {
      if (_mediaStream != null) {
        _mediaStream!.getTracks().forEach((track) => track.stop());
        _mediaStream = null;
      }
      if (_videoElement != null) {
        _videoElement!.srcObject = null;
      }
      _isStreaming = false;
      debugPrint('Web camera stopped');
    } catch (e) {
      debugPrint('Web camera stop error: $e');
    }
  }

  @override
  Widget buildCameraPreview({double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (!_initialized || _videoElement == null) {
      return _buildPlaceholder(width, height);
    }

    return Container(
      width: width,
      height: height ?? 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HtmlElementView(viewType: _viewId),
      ),
    );
  }

  Widget _buildPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height ?? 200,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off, color: Colors.white38, size: 32),
          SizedBox(height: 8),
          Text('摄像头未就绪', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    stopCamera();
    _videoElement = null;
    _initialized = false;
  }
}
