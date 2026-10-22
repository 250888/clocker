import 'dart:js_util' as js_util;
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

bool _jsWhiteNoiseAvailable() {
  try {
    return js_util.hasProperty(html.window, 'startWhiteNoise');
  } catch (_) {
    return false;
  }
}

Future<bool> platformPlayWhiteNoise(String soundId, double volume) async {
  if (!_jsWhiteNoiseAvailable()) {
    debugPrint('JS white noise not available, falling back');
    return false;
  }
  try {
    final result = js_util.callMethod(html.window, 'startWhiteNoise', [soundId, volume]);
    return result == true;
  } catch (e) {
    debugPrint('JS white noise error: $e');
    return false;
  }
}

Future<void> platformStopWhiteNoise() async {
  if (!_jsWhiteNoiseAvailable()) return;
  try {
    js_util.callMethod(html.window, 'stopWhiteNoise', []);
  } catch (e) {
    debugPrint('JS stop noise error: $e');
  }
}

Future<void> platformSetNoiseVolume(double volume) async {
  if (!_jsWhiteNoiseAvailable()) return;
  try {
    js_util.callMethod(html.window, 'setNoiseVolume', [volume]);
  } catch (e) {
    debugPrint('JS set volume error: $e');
  }
}

/// Web 端优先使用 index.html 里的钟鸣合成（谐波 + 包络，听感比 WAV 更自然）。
Future<bool> platformPlayChime() async {
  if (!_jsWhiteNoiseAvailable()) return false;
  try {
    final result = js_util.callMethod(html.window, 'playChime', []);
    return result == true;
  } catch (e) {
    debugPrint('JS chime error: $e');
    return false;
  }
}
