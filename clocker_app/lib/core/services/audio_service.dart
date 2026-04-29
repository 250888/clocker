import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  AudioPlayer? _ambientPlayer;
  bool _isPlaying = false;
  String _currentSound = 'none';
  double _volume = 0.5;

  bool get isPlaying => _isPlaying;
  String get currentSound => _currentSound;

  final List<Map<String, dynamic>> soundOptions = [
    {'id': 'rain', 'name': '雨声', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'id': 'fire', 'name': '炉火', 'icon': Icons.local_fire_department, 'color': Colors.orange},
    {'id': 'ocean', 'name': '海浪', 'icon': Icons.waves, 'color': Colors.teal},
    {'id': 'wind', 'name': '微风', 'icon': Icons.air, 'color': Colors.cyan},
    {'id': 'forest', 'name': '森林', 'icon': Icons.forest, 'color': Colors.green},
    {'id': 'cafe', 'name': '咖啡馆', 'icon': Icons.coffee, 'color': Colors.brown},
  ];

  static const int _sampleRate = 22050;

  Uint8List _generateWav(Uint8List pcmData, int sampleRate, int channels) {
    final dataSize = pcmData.length;
    final header = ByteData(44);
    header.setUint32(0, 0x52494646, Endian.big);
    header.setUint32(4, 36 + dataSize, Endian.little);
    header.setUint32(8, 0x57415645, Endian.big);
    header.setUint32(12, 0x666d7420, Endian.big);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * channels * 2, Endian.little);
    header.setUint16(32, channels * 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    header.setUint32(36, 0x64617461, Endian.big);
    header.setUint32(40, dataSize, Endian.little);
    return Uint8List.fromList([...header.buffer.asUint8List(), ...pcmData]);
  }

  double _lowPass(double input, double prev, double alpha) {
    return prev + alpha * (input - prev);
  }

  Uint8List _generateNoisePcm(String soundId, double volume, int durationSeconds) {
    final totalSamples = _sampleRate * durationSeconds;
    final pcm = Int16List(totalSamples);
    final random = Random();

    double prevSample = 0;
    double prevSample2 = 0;
    double prevSample3 = 0;
    double lfoPhase = 0;
    double envelope = 1.0;

    for (int i = 0; i < totalSamples; i++) {
      double sample = 0;
      final t = i / _sampleRate;
      final rawNoise = (random.nextDouble() * 2 - 1);

      switch (soundId) {
        case 'rain':
          // 雨声: 随机噪声 + 偶尔放大模拟雨滴
          double rainNoise = rawNoise * 0.3;
          // 低通滤波让雨声更柔和
          rainNoise = _lowPass(rainNoise, prevSample, 0.15);
          // 随机雨滴 - 偶尔的高频脉冲
          if (random.nextDouble() > 0.995) {
            rainNoise += (random.nextDouble() * 2 - 1) * 0.6;
          }
          // 持续的细雨背景
          rainNoise += (random.nextDouble() * 2 - 1) * 0.05;
          sample = rainNoise;
          prevSample = rainNoise;
          break;

        case 'fire':
          // 炉火: 低频随机噪声 + 爆裂声
          double fireNoise = rawNoise * 0.1;
          // 强低通滤波 - 炉火的隆隆声
          fireNoise = _lowPass(fireNoise, prevSample, 0.05);
          // 爆裂声 - 随机高频脉冲
          if (random.nextDouble() > 0.99) {
            final crackleIntensity = random.nextDouble() * 0.8 + 0.2;
            final crackleFreq = 800 + random.nextDouble() * 2000;
            final crackleLen = (_sampleRate * 0.05).toInt();
            for (int j = 0; j < crackleLen && (i + j) < totalSamples; j++) {
              final ct = j / _sampleRate;
              final decay = 1.0 - j / crackleLen;
              final crackle = sin(2 * pi * crackleFreq * ct) * crackleIntensity * decay * 0.4;
              final idx = i + j;
              if (idx < totalSamples) {
                pcm[idx] = (pcm[idx] + (crackle * volume * 32767).toInt())
                    .clamp(-32768, 32767)
                    .toInt();
              }
            }
          }
          // 低频隆隆声
          fireNoise += sin(2 * pi * 60 * t) * 0.05;
          sample = fireNoise;
          prevSample = fireNoise;
          break;

        case 'ocean':
          // 海浪: 正弦波 + 噪声模拟潮汐
          lfoPhase += 0.08 / _sampleRate * 2 * pi;
          final tideMod = (sin(lfoPhase) + 1) * 0.5; // 0-1 潮汐周期
          // 波浪噪声
          double waveNoise = rawNoise * 0.12 * tideMod;
          waveNoise = _lowPass(waveNoise, prevSample, 0.1);
          // 主波浪声 - 多个正弦波叠加
          final wave1 = sin(2 * pi * 0.15 * t) * 0.15;
          final wave2 = sin(2 * pi * 0.08 * t + 1.5) * 0.1;
          final wave3 = sin(2 * pi * 0.25 * t + 0.7) * 0.05;
          // 泡沫声 - 高频噪声在波浪峰值时出现
          double foam = 0;
          if (tideMod > 0.7) {
            foam = (random.nextDouble() * 2 - 1) * 0.08 * (tideMod - 0.7) / 0.3;
          }
          sample = waveNoise + wave1 + wave2 + wave3 + foam;
          prevSample = waveNoise;
          break;

        case 'wind':
          // 微风: 滤波噪声模拟风声
          double windNoise = rawNoise * 0.15;
          // 多级低通滤波模拟风声特征
          windNoise = _lowPass(windNoise, prevSample, 0.08);
          windNoise = _lowPass(windNoise, prevSample2, 0.12);
          // 风的阵风效果 - LFO调制
          lfoPhase += 0.15 / _sampleRate * 2 * pi;
          final gustMod = (sin(lfoPhase) + 1) * 0.5;
          windNoise *= 0.3 + gustMod * 0.7;
          // 呼啸声 - 高频分量
          final whistle = sin(2 * pi * (400 + gustMod * 200) * t) * 0.02 * gustMod;
          sample = windNoise + whistle;
          prevSample2 = prevSample;
          prevSample = windNoise;
          break;

        case 'forest':
          // 森林: 安静底噪 + 偶尔鸟鸣声
          double forestNoise = rawNoise * 0.02;
          forestNoise = _lowPass(forestNoise, prevSample, 0.05);
          // 虫鸣背景 - 高频持续声
          forestNoise += sin(2 * pi * 4500 * t) * 0.008 * (sin(2 * pi * 8 * t) * 0.5 + 0.5);
          forestNoise += sin(2 * pi * 5200 * t) * 0.005 * (sin(2 * pi * 11 * t) * 0.5 + 0.5);
          // 鸟鸣声 - 随机出现的啁啾声
          if (random.nextDouble() > 0.998) {
            final birdFreq = 2500 + random.nextDouble() * 2500;
            final chirpLen = (_sampleRate * (0.08 + random.nextDouble() * 0.15)).toInt();
            final chirpType = random.nextInt(3);
            for (int j = 0; j < chirpLen && (i + j) < totalSamples; j++) {
              final ct = j / _sampleRate;
              final decay = 1.0 - j / chirpLen;
              double chirp;
              if (chirpType == 0) {
                // 上升啁啾
                final freq = birdFreq + (birdFreq * 0.5) * j / chirpLen;
                chirp = sin(2 * pi * freq * ct) * 0.25 * decay;
              } else if (chirpType == 1) {
                // 双音啁啾
                final freq1 = birdFreq;
                final freq2 = birdFreq * 1.2;
                chirp = (sin(2 * pi * freq1 * ct) + sin(2 * pi * freq2 * ct)) * 0.12 * decay;
              } else {
                // 颤音
                final freq = birdFreq + sin(2 * pi * 30 * ct) * 200;
                chirp = sin(2 * pi * freq * ct) * 0.2 * decay;
              }
              final idx = i + j;
              if (idx < totalSamples) {
                pcm[idx] = (pcm[idx] + (chirp * volume * 32767).toInt())
                    .clamp(-32768, 32767)
                    .toInt();
              }
            }
          }
          // 树叶沙沙声
          if (random.nextDouble() > 0.97) {
            forestNoise += (random.nextDouble() * 2 - 1) * 0.03;
          }
          sample = forestNoise;
          prevSample = forestNoise;
          break;

        case 'cafe':
          // 咖啡馆: 中等噪声 + 人声模拟
          double cafeNoise = rawNoise * 0.08;
          cafeNoise = _lowPass(cafeNoise, prevSample, 0.2);
          // 人声模拟 - 多个低频共振峰
          if (random.nextDouble() > 0.985) {
            envelope = 0.5 + random.nextDouble() * 0.5;
          }
          envelope *= 0.98;
          final voice1 = sin(2 * pi * 200 * t) * 0.03 * envelope;
          final voice2 = sin(2 * pi * 500 * t) * 0.02 * envelope;
          final voice3 = sin(2 * pi * 800 * t) * 0.01 * envelope;
          // 杯碟声
          double clink = 0;
          if (random.nextDouble() > 0.997) {
            clink = sin(2 * pi * 3000 * t) * 0.15;
            final clinkLen = (_sampleRate * 0.03).toInt();
            for (int j = 0; j < clinkLen && (i + j) < totalSamples; j++) {
              final decay = 1.0 - j / clinkLen;
              final idx = i + j;
              if (idx < totalSamples) {
                pcm[idx] = (pcm[idx] + (sin(2 * pi * 3000 * j / _sampleRate) * 0.15 * decay * volume * 32767).toInt())
                    .clamp(-32768, 32767)
                    .toInt();
              }
            }
          }
          // 背景音乐感 - 微弱的和弦
          final bgMusic = sin(2 * pi * 261 * t) * 0.005 + sin(2 * pi * 329 * t) * 0.004;
          sample = cafeNoise + voice1 + voice2 + voice3 + bgMusic;
          prevSample = cafeNoise;
          break;

        default:
          sample = rawNoise * 0.1;
      }

      sample *= volume;
      final int16Sample = (sample * 32767).toInt().clamp(-32768, 32767);
      pcm[i] = pcm[i] + int16Sample;
    }

    // 归一化防止削波
    int maxVal = 1;
    for (int i = 0; i < totalSamples; i++) {
      final abs = pcm[i].abs();
      if (abs > maxVal) maxVal = abs;
    }
    final normFactor = maxVal > 30000 ? 30000.0 / maxVal : 1.0;

    final result = ByteData(totalSamples * 2);
    for (int i = 0; i < totalSamples; i++) {
      result.setInt16(i * 2, (pcm[i] * normFactor).toInt().clamp(-32768, 32767), Endian.little);
    }

    return result.buffer.asUint8List();
  }

  Uint8List _generateTonePcm(double frequency, int durationMs, {double vol = 0.3, double attackMs = 10, double releaseMs = 50}) {
    final totalSamples = (_sampleRate * durationMs / 1000).toInt();
    final pcm = ByteData(totalSamples * 2);
    final attackSamples = (_sampleRate * attackMs / 1000).toInt();
    final releaseSamples = (_sampleRate * releaseMs / 1000).toInt();

    for (int i = 0; i < totalSamples; i++) {
      final t = i / _sampleRate;
      double envelope = 1.0;
      if (i < attackSamples) {
        envelope = i / attackSamples;
      } else if (i > totalSamples - releaseSamples) {
        envelope = (totalSamples - i) / releaseSamples;
      }
      final sample = sin(2 * pi * frequency * t) * vol * envelope;
      pcm.setInt16(i * 2, (sample * 32767).toInt().clamp(-32768, 32767), Endian.little);
    }

    return pcm.buffer.asUint8List();
  }

  Uint8List _generateChordPcm(List<double> frequencies, int durationMs, {double vol = 0.2}) {
    final totalSamples = (_sampleRate * durationMs / 1000).toInt();
    final pcm = ByteData(totalSamples * 2);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / _sampleRate;
      double envelope = 1.0;
      if (i < totalSamples * 0.05) {
        envelope = i / (totalSamples * 0.05);
      } else if (i > totalSamples * 0.7) {
        envelope = (totalSamples - i) / (totalSamples * 0.3);
      }
      double sample = 0;
      for (final freq in frequencies) {
        sample += sin(2 * pi * freq * t) * vol * envelope;
      }
      sample /= frequencies.length;
      pcm.setInt16(i * 2, (sample * 32767).toInt().clamp(-32768, 32767), Endian.little);
    }

    return pcm.buffer.asUint8List();
  }

  Future<void> playWhiteNoise(String soundId, {double volume = 0.5}) async {
    _currentSound = soundId;
    _volume = volume;
    _isPlaying = true;

    try {
      await _ambientPlayer?.stop();
      _ambientPlayer = AudioPlayer();

      final pcmData = _generateNoisePcm(soundId, volume, 30);
      final wavData = _generateWav(pcmData, _sampleRate, 1);

      await _ambientPlayer!.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer!.setVolume(volume);
      await _ambientPlayer!.play(BytesSource(wavData));

      debugPrint('Playing white noise: $soundId');
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  Future<void> stopWhiteNoise() async {
    _isPlaying = false;
    _currentSound = 'none';
    try {
      await _ambientPlayer?.stop();
    } catch (e) {
      debugPrint('Audio stop error: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _ambientPlayer?.setVolume(_volume);
    } catch (e) {
      debugPrint('Volume error: $e');
    }
  }

  // 完成音: C-E-G 大三和弦
  Future<void> playCompletionSound() async {
    try {
      // C5=523, E5=659, G5=784 大三和弦
      final chord = _generateChordPcm([523.25, 659.25, 783.99], 600, vol: 0.25);
      final wav = _generateWav(chord, _sampleRate, 1);
      await _sfxPlayer.play(BytesSource(wav));
      debugPrint('Completion sound: C-E-G major chord');
    } catch (e) {
      debugPrint('Completion sound error: $e');
    }
  }

  // 分心警告: 低频 200Hz
  Future<void> playDistractionSound() async {
    try {
      final pcm = _generateTonePcm(200, 300, vol: 0.4, attackMs: 5, releaseMs: 100);
      final wav = _generateWav(pcm, _sampleRate, 1);
      await _sfxPlayer.play(BytesSource(wav));
      debugPrint('Distraction warning: 200Hz');
    } catch (e) {
      debugPrint('Distraction sound error: $e');
    }
  }

  // 成就音: 高音频段上升
  Future<void> playAchievementSound() async {
    try {
      final a = _generateTonePcm(880, 100, vol: 0.2);
      final b = _generateTonePcm(1100, 150, vol: 0.25);
      final c = _generateTonePcm(1320, 200, vol: 0.3);
      final d = _generateTonePcm(1760, 400, vol: 0.25);
      final combined = Uint8List.fromList([...a, ...b, ...c, ...d]);
      final wav = _generateWav(combined, _sampleRate, 1);
      await _sfxPlayer.play(BytesSource(wav));
      debugPrint('Achievement sound: ascending tones');
    } catch (e) {
      debugPrint('Achievement sound error: $e');
    }
  }

  // 滴答声: 1kHz 短音
  Future<void> playTickSound() async {
    try {
      final pcm = _generateTonePcm(1000, 50, vol: 0.15, attackMs: 2, releaseMs: 20);
      final wav = _generateWav(pcm, _sampleRate, 1);
      await _sfxPlayer.play(BytesSource(wav));
    } catch (e) {
      debugPrint('Tick sound error: $e');
    }
  }

  void adjustToFlowRate(double flowRate) {
    if (!_isPlaying) return;
    final baseVolume = 0.3;
    final flowVolume = (flowRate - 1.0).clamp(0.0, 1.0) * 0.5;
    setVolume(baseVolume + flowVolume);
  }

  void dispose() {
    _ambientPlayer?.dispose();
    _sfxPlayer.dispose();
  }
}
