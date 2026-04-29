import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'camera_service_factory.dart';

CameraServiceInterface createCameraService() => NativeCameraService();

class NativeCameraService implements CameraServiceInterface {
  bool _isStreaming = false;
  bool _initialized = false;

  @override
  bool get isStreaming => _isStreaming;

  @override
  Future<bool> initialize() async {
    _initialized = true;
    debugPrint('Native camera service initialized (simulated)');
    return true;
  }

  @override
  Future<void> startCamera() async {
    if (!_initialized || _isStreaming) return;
    _isStreaming = true;
    debugPrint('Native camera started (simulated)');
  }

  @override
  Future<void> stopCamera() async {
    _isStreaming = false;
    debugPrint('Native camera stopped');
  }

  @override
  Widget buildCameraPreview({double? width, double? height, BoxFit fit = BoxFit.cover}) {
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
          Icon(
            _isStreaming ? Icons.videocam : Icons.videocam_off,
            color: _isStreaming ? Colors.greenAccent : Colors.white38,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            _isStreaming ? '摄像头已启动' : '摄像头未启动',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          if (Platform.isWindows) ...[
            SizedBox(height: 8),
            Text(
              'Windows 桌面版摄像头预览',
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    stopCamera();
    _initialized = false;
  }
}
