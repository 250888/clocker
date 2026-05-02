import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'web_camera_service.dart';

WebCameraService createWebCameraService() => NativeCameraService();

class NativeCameraService implements WebCameraService {
  CameraController? _controller;
  bool _isActive = false;
  bool _isAvailable = true;

  @override
  bool get isActive => _isActive;

  @override
  bool get isAvailable => _isAvailable;

  @override
  Future<bool> startCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _isAvailable = false;
        debugPrint('Native camera: no cameras found');
        return false;
      }

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isActive = true;
      debugPrint('Native camera started: ${frontCamera.name}');
      return true;
    } catch (e) {
      _isAvailable = false;
      debugPrint('Native camera start failed: $e');
      return false;
    }
  }

  @override
  void stopCamera() {
    _controller?.dispose();
    _controller = null;
    _isActive = false;
    debugPrint('Native camera stopped');
  }

  @override
  void setOpacity(double opacity) {}

  @override
  void setMirror(bool mirror) {}

  @override
  Widget? buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 200,
        height: 150,
        child: CameraPreview(_controller!),
      ),
    );
  }

  @override
  void dispose() {
    stopCamera();
  }
}
