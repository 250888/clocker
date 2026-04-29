import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  bool _isInitialized = false;
  bool _isStreaming = false;
  Uint8List? _latestFrame;
  double _attentionScore = 1.0;
  bool _faceDetected = false;
  double _eyeOpenness = 1.0;
  double _headPose = 0.0;
  Timer? _detectionTimer;

  bool get isInitialized => _isInitialized;
  bool get isStreaming => _isStreaming;
  Uint8List? get latestFrame => _latestFrame;
  double get attentionScore => _attentionScore;
  bool get faceDetected => _faceDetected;
  double get eyeOpenness => _eyeOpenness;
  double get headPose => _headPose;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = true;
      debugPrint('Camera service initialized');
      return true;
    } catch (e) {
      debugPrint('Camera init error: $e');
      return false;
    }
  }

  void startStreaming() {
    if (_isStreaming) return;
    _isStreaming = true;
    _detectionTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _simulateDetection();
    });
    debugPrint('Camera streaming started');
  }

  void stopStreaming() {
    _isStreaming = false;
    _detectionTimer?.cancel();
    debugPrint('Camera streaming stopped');
  }

  void _simulateDetection() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    _faceDetected = random > 5;
    _eyeOpenness = _faceDetected ? (0.7 + (random % 30) / 100.0) : 0.0;
    _headPose = ((random % 40) - 20) / 100.0;

    _attentionScore = 1.0;
    if (!_faceDetected) _attentionScore -= 0.4;
    if (_eyeOpenness < 0.3) _attentionScore -= 0.2;
    if (_headPose.abs() > 0.5) _attentionScore -= 0.2;
    _attentionScore = _attentionScore.clamp(0.0, 1.0);
  }

  void dispose() {
    stopStreaming();
    _isInitialized = false;
  }
}
