import 'package:flutter_test/flutter_test.dart';

import 'package:clocker/core/services/audio_service.dart';

/// 音频合成质量护栏：环境音与钟鸣必须非空、有能量、无静音/爆音。
void main() {
  const sounds = ['rain', 'fire', 'ocean', 'wind', 'forest', 'cafe'];

  for (final id in sounds) {
    test('环境音 $id 合成正常（非空、有能量、未削波）', () {
      final info = AudioService.debugInspectNoise(id, 2);
      expect(info['bytes']!, greaterThan(0), reason: '$id 应有 PCM 输出');
      expect(info['peak']!, greaterThan(0.05), reason: '$id 不能是静音');
      expect(info['peak']!, lessThan(1.0), reason: '$id 不应削波');
      expect(info['rms']!, greaterThan(0.002), reason: '$id 应有可听能量');
    });
  }

  test('完成音是暖钟鸣（有能量且未削波）', () {
    final bytes = AudioService.debugInspectChime();
    expect(bytes, isNotEmpty);
    // 16bit mono：前两字节解析峰值
    var peak = 0.0;
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      final v = ((bytes[i + 1] << 8) | bytes[i]).toSigned(16) / 32768.0;
      if (v.abs() > peak) peak = v.abs();
    }
    expect(peak, greaterThan(0.2), reason: '完成音应有能量');
    expect(peak, lessThan(1.0), reason: '完成音不应削波');
  });
}
