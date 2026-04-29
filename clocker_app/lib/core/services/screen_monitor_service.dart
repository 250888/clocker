import 'dart:async';
import 'package:flutter/material.dart';

class ScreenMonitorService {
  static final ScreenMonitorService _instance = ScreenMonitorService._internal();
  factory ScreenMonitorService() => _instance;
  ScreenMonitorService._internal();

  bool _isMonitoring = false;
  Timer? _monitorTimer;
  DateTime? _lastActivity;
  Duration _productiveTime = Duration.zero;
  Duration _unproductiveTime = Duration.zero;
  String _currentApp = 'Clocker';
  int _appSwitchCount = 0;
  bool _isPageVisible = true;
  DateTime? _sessionStart;
  Map<String, Duration> _appTimeMap = {};
  List<AppSwitchEvent> _switchHistory = [];

  final List<String> _productiveApps = [
    'clocker', 'code', 'vscode', 'visual studio code', 'android studio',
    'intellij', 'idea', 'pycharm', 'webstorm', 'clion', 'rider',
    'chrome', 'edge', 'firefox', 'safari', 'msedge',
    'word', 'excel', 'powerpoint', 'onenote', 'outlook',
    'notion', 'obsidian', 'typora', 'marktext',
    'terminal', 'windowsterminal', 'powershell', 'cmd', 'gitbash',
    'flutter', 'dart', 'visualstudio', 'devenv',
    'github', 'git', 'sourcetree', 'fork',
    'figma', 'sketch', 'xd', 'blender',
    'sublime', 'atom', 'vim', 'nvim', 'emacs',
    'datagrip', 'dbeaver', 'navicat', 'robo3t',
    'postman', 'insomnia',
  ];

  final List<String> _unproductiveApps = [
    'youtube', 'tiktok', 'instagram', 'twitter', 'x', 'facebook',
    'wechat', 'weixin', 'qq', 'tim', 'bilibili', 'netflix',
    'game', 'steam', 'epic', 'origin', 'ubisoft',
    'discord', 'telegram', 'whatsapp', 'signal',
    'reddit', 'twitch', 'hulu', 'disney',
    'douyin', 'kuaishou', 'zhihu', 'weibo',
    'spotify', 'applemusic', 'neteasecloudmusic',
    'lol', 'csgo', 'valorant', 'minecraft', 'genshin',
    'mhw', 'monsterhunter', 'overwatch', 'dota',
  ];

  bool get isMonitoring => _isMonitoring;
  Duration get productiveTime => _productiveTime;
  Duration get unproductiveTime => _unproductiveTime;
  String get currentApp => _currentApp;
  int get appSwitchCount => _appSwitchCount;
  bool get isPageVisible => _isPageVisible;
  Map<String, Duration> get appTimeMap => Map.unmodifiable(_appTimeMap);
  List<AppSwitchEvent> get switchHistory => List.unmodifiable(_switchHistory);

  double get productivityRatio {
    final total = _productiveTime + _unproductiveTime;
    if (total.inSeconds == 0) return 1.0;
    return _productiveTime.inSeconds / total.inSeconds;
  }

  AppCategory categorizeApp(String appName) {
    final lower = appName.toLowerCase().trim();
    if (_unproductiveApps.any((p) => lower.contains(p))) {
      return AppCategory.entertainment;
    }
    if (_productiveApps.any((p) => lower.contains(p))) {
      return AppCategory.productive;
    }
    return AppCategory.neutral;
  }

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _sessionStart = DateTime.now();
    _lastActivity = DateTime.now();
    _productiveTime = Duration.zero;
    _unproductiveTime = Duration.zero;
    _appSwitchCount = 0;
    _appTimeMap.clear();
    _switchHistory.clear();

    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isMonitoring) return;
      _checkActivity();
    });

    debugPrint('Screen monitoring started');
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _monitorTimer?.cancel();
    debugPrint('Screen monitoring stopped');
  }

  void _checkActivity() {
    final now = DateTime.now();

    if (_lastActivity != null) {
      final elapsed = now.difference(_lastActivity!);
      final category = categorizeApp(_currentApp);

      _appTimeMap[_currentApp] = (_appTimeMap[_currentApp] ?? Duration.zero) + elapsed;

      if (_isPageVisible) {
        switch (category) {
          case AppCategory.productive:
            _productiveTime += elapsed;
            break;
          case AppCategory.entertainment:
            _unproductiveTime += elapsed;
            break;
          case AppCategory.neutral:
            _productiveTime += elapsed * 0.5;
            _unproductiveTime += elapsed * 0.5;
            break;
        }
      } else {
        _unproductiveTime += elapsed;
      }
    }
    _lastActivity = now;
  }

  void reportPageVisibility(bool visible) {
    if (_isPageVisible != visible) {
      _checkActivity();
      _isPageVisible = visible;
      if (!visible) {
        _currentApp = 'LeftPage';
      } else {
        _currentApp = 'Clocker';
      }
      debugPrint('Page visibility: ${visible ? "visible" : "hidden"}');
    }
  }

  void reportForegroundApp(String appName) {
    if (_currentApp != appName) {
      _checkActivity();
      _appSwitchCount++;
      _switchHistory.add(AppSwitchEvent(
        fromApp: _currentApp,
        toApp: appName,
        timestamp: DateTime.now(),
        category: categorizeApp(appName),
      ));
      debugPrint('App switched: $_currentApp -> $appName (${categorizeApp(appName).name})');
    }
    _currentApp = appName;
  }

  Map<String, dynamic> getReport() {
    final totalMinutes = (_productiveTime + _unproductiveTime).inMinutes;
    return {
      'productiveMinutes': _productiveTime.inMinutes,
      'unproductiveMinutes': _unproductiveTime.inMinutes,
      'productivityRatio': productivityRatio,
      'currentApp': _currentApp,
      'appSwitchCount': _appSwitchCount,
      'isPageVisible': _isPageVisible,
      'appTimeMap': _appTimeMap.map((k, v) => MapEntry(k, v.inSeconds)),
      'totalMinutes': totalMinutes,
      'sessionDuration': _sessionStart != null
          ? DateTime.now().difference(_sessionStart!).inMinutes
          : 0,
    };
  }

  void reset() {
    _productiveTime = Duration.zero;
    _unproductiveTime = Duration.zero;
    _appSwitchCount = 0;
    _lastActivity = DateTime.now();
    _sessionStart = DateTime.now();
    _appTimeMap.clear();
    _switchHistory.clear();
  }
}

enum AppCategory { productive, entertainment, neutral }

class AppSwitchEvent {
  final String fromApp;
  final String toApp;
  final DateTime timestamp;
  final AppCategory category;

  AppSwitchEvent({
    required this.fromApp,
    required this.toApp,
    required this.timestamp,
    required this.category,
  });
}
