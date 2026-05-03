import 'dart:io' show Platform;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'web_camera_service.dart';

WebCameraService createWebCameraService() => NativeCameraService();

class NativeCameraService implements WebCameraService {
  CameraController? _controller;
  bool _isActive = false;
  bool _isAvailable = true;
  bool _mirror = true;

  @override
  bool get isActive => _isActive;

  @override
  bool get isAvailable => _isAvailable;

  Future<bool> _requestPermission() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    var status = await Permission.camera.status;
    if (status.isGranted) return true;

    status = await Permission.camera.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      await Future.delayed(const Duration(seconds: 2));
      status = await Permission.camera.status;
      return status.isGranted;
    }

    return false;
  }

  @override
  Future<bool> startCamera() async {
    try {
      final hasPermission = await _requestPermission();
      if (!hasPermission) {
        _isAvailable = false;
        debugPrint('Native camera: permission denied');
        return false;
      }

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
  void setMirror(bool mirror) {
    _mirror = mirror;
  }

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
        child: Transform(
          alignment: Alignment.center,
          transform: _mirror
              ? Matrix4.rotationY(3.14159265)
              : Matrix4.identity(),
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  @override
  void dispose() {
    stopCamera();
  }
}
