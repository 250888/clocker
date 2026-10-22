import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 真实环境录音资产（CC0）存在性守卫。
/// 5 种为 sfxmint CC0 真实录音（经 make_ambience_assets.py 处理成无缝循环 WAV）；
/// 咖啡馆无合适 CC0 源，保留程序合成（无资产文件属正常）。
void main() {
  test('assets/audio 下五种真实录音齐备', () {
    const dir = 'assets/audio';
    expect(Directory(dir).existsSync(), isTrue, reason: '$dir 目录应存在');
    for (final name in ['rain', 'fire', 'ocean', 'wind', 'forest']) {
      final f = File('$dir/$name.wav');
      expect(f.existsSync(), isTrue, reason: '$name.wav 应存在');
      final size = f.lengthSync();
      expect(size, greaterThan(100 * 1024),
          reason: '$name.wav 应为完整录音（>100KB），当前 $size B');
    }
  });
}
