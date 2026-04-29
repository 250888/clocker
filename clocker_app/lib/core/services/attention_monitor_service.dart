import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'attention_camera_stub.dart';

class AttentionMonitorService {
  static final AttentionMonitorService _instance = AttentionMonitorService._internal();
  factory AttentionMonitorService() => _instance;
  AttentionMonitorService._internal();

  bool _isMonitoring = false;
  Timer? _monitorTimer;
  double _attentionScore = 1.0;
  int _distractionEvents = 0;
  DateTime? _lastAttentionTime;
  Duration _focusedDuration = Duration.zero;
  Duration _distractedDuration = Duration.zero;
  bool _isInFlowState = false;
  bool _cameraAvailable = false;
  DateTime? _focusStartTime;

  // 注意力历史记录（最近60次检测，5秒一次=5分钟）
  final List<double> _scoreHistory = [];
  static const int _maxHistoryLength = 60;

  // 心流状态检测参数
  static const Duration _flowStateThreshold = Duration(minutes: 15);
  static const double _flowAttentionThreshold = 0.85;

  // 模拟摄像头检测参数
  double _faceDetected = 1.0;
  double _eyeOpenness = 1.0;
  double _headPose = 0.0;
  double _blinkRate = 0.0;
  int _blinkCount = 0;
  DateTime? _lastBlinkTime;

  bool get isMonitoring => _isMonitoring;
  double get attentionScore => _attentionScore;
  int get distractionEvents => _distractionEvents;
  bool get isInFlowState => _isInFlowState;
  Duration get focusedDuration => _focusedDuration;
  Duration get distractedDuration => _distractedDuration;
  bool get cameraAvailable => _cameraAvailable;
  List<double> get scoreHistory => List.unmodifiable(_scoreHistory);
  double get faceDetected => _faceDetected;
  double get eyeOpenness => _eyeOpenness;
  double get headPose => _headPose;
  double get blinkRate => _blinkRate;

  Duration get currentFocusStreak {
    if (_focusStartTime == null) return Duration.zero;
    return DateTime.now().difference(_focusStartTime!);
  }

  double get averageAttention {
    if (_scoreHistory.isEmpty) return _attentionScore;
    return _scoreHistory.reduce((a, b) => a + b) / _scoreHistory.length;
  }

  double get focusStability {
    if (_scoreHistory.length < 5) return 1.0;
    final recent = _scoreHistory.sublist(_scoreHistory.length - 10);
    final avg = recent.reduce((a, b) => a + b) / recent.length;
    final variance = recent.map((s) => pow(s - avg, 2)).reduce((a, b) => a + b) / recent.length;
    return (1.0 - sqrt(variance)).clamp(0.0, 1.0);
  }

  final AttentionCameraInterface _camera = createAttentionCamera();

  Future<void> initialize() async {
    try {
      _cameraAvailable = await _camera.start();
      debugPrint('Camera initialized (available: $_cameraAvailable)');
    } catch (e) {
      _cameraAvailable = false;
      debugPrint('Camera not available: $e');
    }
  }

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _lastAttentionTime = DateTime.now();
    _focusStartTime = DateTime.now();
    _attentionScore = 1.0;
    _distractionEvents = 0;
    _focusedDuration = Duration.zero;
    _distractedDuration = Duration.zero;
    _isInFlowState = false;
    _scoreHistory.clear();
    _blinkCount = 0;
    _lastBlinkTime = null;

    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isMonitoring) return;
      _checkAttention();
    });

    debugPrint('Attention monitoring started (camera: $_cameraAvailable)');
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _monitorTimer?.cancel();
    _camera.stop();
    debugPrint('Attention monitoring stopped');
  }

  void _checkAttention() {
    final now = DateTime.now();
    if (_lastAttentionTime == null) {
      _lastAttentionTime = now;
      return;
    }

    _simulateCameraDetection();

    double rawScore = _calculateAttentionScore();

    // 平滑过渡 - 避免分数突变
    final smoothing = 0.3;
    _attentionScore = _attentionScore * (1 - smoothing) + rawScore * smoothing;
    _attentionScore = _attentionScore.clamp(0.0, 1.0);

    _camera.updateAttention(_attentionScore);

    // 记录历史
    _scoreHistory.add(_attentionScore);
    if (_scoreHistory.length > _maxHistoryLength) {
      _scoreHistory.removeAt(0);
    }

    // 判断是否分心
    final isDistracted = _attentionScore < 0.4;

    if (isDistracted) {
      _distractedDuration += const Duration(seconds: 5);
      _distractionEvents++;
      _isInFlowState = false;
      _focusStartTime = null;
      debugPrint('Distraction detected (event #$_distractionEvents, score: ${(_attentionScore * 100).toInt()}%)');
    } else {
      _focusedDuration += const Duration(seconds: 5);

      // 心流状态检测: 连续15分钟+高注意力
      if (_attentionScore >= _flowAttentionThreshold) {
        if (_focusStartTime == null) {
          _focusStartTime = now;
        }
        final focusDuration = now.difference(_focusStartTime!);
        if (focusDuration >= _flowStateThreshold && !_isInFlowState) {
          _isInFlowState = true;
          debugPrint('Flow state detected! (${focusDuration.inMinutes}min continuous focus)');
        }
      } else {
        // 注意力不够高，重置心流计时
        if (!_isInFlowState) {
          _focusStartTime = now;
        }
      }
    }

    _lastAttentionTime = now;
  }

  void _simulateCameraDetection() {
    final random = Random();

    // 模拟人脸检测
    // 大部分时间人脸在画面中，偶尔离开
    if (random.nextDouble() > 0.03) {
      _faceDetected = 1.0;
    } else {
      _faceDetected = 0.0;
    }

    // 模拟眼睛开合度
    // 正常情况下眼睛是睁开的，偶尔眨眼
    if (random.nextDouble() > 0.05) {
      _eyeOpenness = 0.8 + random.nextDouble() * 0.2;
    } else {
      _eyeOpenness = random.nextDouble() * 0.3;
      _blinkCount++;
      final blinkInterval = _lastBlinkTime != null
          ? DateTime.now().difference(_lastBlinkTime!).inSeconds
          : 10;
      _blinkRate = 60.0 / blinkInterval.clamp(1, 60);
      _lastBlinkTime = DateTime.now();
    }

    // 模拟头部姿态（0=正面, 负值=左偏, 正值=右偏）
    _headPose = (random.nextDouble() - 0.5) * 0.3;
    // 偶尔大幅转头 = 分心
    if (random.nextDouble() > 0.95) {
      _headPose = (random.nextDouble() - 0.5) * 2.0;
    }
  }

  double _calculateAttentionScore() {
    double score = 1.0;

    // 人脸检测权重 (40%)
    if (_faceDetected < 0.5) {
      score -= 0.4;
    }

    // 眼睛开合度权重 (25%)
    if (_eyeOpenness < 0.3) {
      // 眨眼 - 轻微扣分
      score -= 0.05;
    } else if (_eyeOpenness < 0.5) {
      // 半闭眼 - 可能犯困
      score -= 0.2;
    }

    // 头部姿态权重 (20%)
    final headPoseAbs = _headPose.abs();
    if (headPoseAbs > 0.8) {
      // 大幅转头 = 明显分心
      score -= 0.3;
    } else if (headPoseAbs > 0.4) {
      // 轻微偏头
      score -= 0.1;
    }

    // 眨眼频率权重 (15%)
    // 正常眨眼频率 15-20次/分钟
    if (_blinkRate > 0 && _blinkRate < 5) {
      // 眨眼太少 - 可能盯着屏幕太久
      score -= 0.05;
    } else if (_blinkRate > 30) {
      // 眨眼太多 - 可能犯困或分心
      score -= 0.15;
    }

    // 时间衰减 - 长时间专注后注意力自然下降
    if (_focusedDuration.inMinutes > 45) {
      final fatigueFactor = ((_focusedDuration.inMinutes - 45) / 45.0).clamp(0.0, 0.3);
      score -= fatigueFactor;
    }

    return score.clamp(0.0, 1.0);
  }

  void reportDistraction() {
    _distractionEvents++;
    _attentionScore = (_attentionScore - 0.15).clamp(0.0, 1.0);
    _isInFlowState = false;
    _focusStartTime = null;
    _scoreHistory.add(_attentionScore);
    if (_scoreHistory.length > _maxHistoryLength) {
      _scoreHistory.removeAt(0);
    }
  }

  void reportFocus() {
    _attentionScore = (_attentionScore + 0.05).clamp(0.0, 1.0);
  }

  Map<String, dynamic> getReport() {
    return {
      'attentionScore': _attentionScore,
      'averageAttention': averageAttention,
      'focusStability': focusStability,
      'distractionEvents': _distractionEvents,
      'focusedMinutes': _focusedDuration.inMinutes,
      'distractedMinutes': _distractedDuration.inMinutes,
      'isInFlowState': _isInFlowState,
      'focusStreakMinutes': currentFocusStreak.inMinutes,
      'faceDetected': _faceDetected,
      'eyeOpenness': _eyeOpenness,
      'headPose': _headPose,
      'blinkRate': _blinkRate,
    };
  }

  void reset() {
    _attentionScore = 1.0;
    _distractionEvents = 0;
    _focusedDuration = Duration.zero;
    _distractedDuration = Duration.zero;
    _isInFlowState = false;
    _lastAttentionTime = DateTime.now();
    _focusStartTime = DateTime.now();
    _scoreHistory.clear();
    _blinkCount = 0;
    _lastBlinkTime = null;
  }
}
