import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'native_audio_stub.dart' if (dart.library.html) 'web_audio_impl.dart';

class _NoiseParams {
  final String soundId;
  final double volume;
  final int durationSeconds;
  _NoiseParams(this.soundId, this.volume, this.durationSeconds);
}

Uint8List _generateNoisePcmIsolate(_NoiseParams params) {
  return _generateNoisePcmStatic(
    params.soundId,
    params.volume,
    params.durationSeconds,
  );
}

Uint8List _generateNoisePcmStatic(
  String soundId,
  double volume,
  int durationSeconds,
) {
  const sampleRate = 44100;
  final totalSamples = sampleRate * durationSeconds;
  final pcm = Float64List(totalSamples);
  final random = Random();
  final noise = List.generate(totalSamples, (_) => random.nextDouble() * 2 - 1);

  // ── 粉噪声基底（Paul Kellet 滤波器，-3dB/oct 谱）──────────────────
  // 白噪声每赫兹能量相同，高频刺耳；粉噪声能量随频率递减，
  // 才是雨/风/篝火/海浪共有的"自然"底色。
  final pink = Float64List(totalSamples);
  double pk0 = 0, pk1 = 0, pk2 = 0, pk3 = 0, pk4 = 0, pk5 = 0, pk6 = 0;
  for (var i = 0; i < totalSamples; i++) {
    final w = noise[i];
    pk0 = 0.99886 * pk0 + w * 0.0555179;
    pk1 = 0.99332 * pk1 + w * 0.0750759;
    pk2 = 0.96900 * pk2 + w * 0.1538520;
    pk3 = 0.86650 * pk3 + w * 0.3104856;
    pk4 = 0.55000 * pk4 + w * 0.5329522;
    pk5 = -0.7616 * pk5 - w * 0.0168980;
    pk6 = w * 0.115926;
    pink[i] = (pk0 + pk1 + pk2 + pk3 + pk4 + pk5 + pk6) * 0.11;
  }

  // ── 慢速"呼吸"调制（~0.35Hz 与 ~3.5Hz 两层）───────────────────────
  // 纯静态的循环底噪听起来是"死"的；真实环境的响度一直在缓慢起伏。
  final env = Float64List(totalSamples);
  double lfo1 = 0, lfo2 = 0;
  for (var i = 0; i < totalSamples; i++) {
    lfo1 += (noise[i] - lfo1) * 0.00008;
    lfo2 += (noise[i] - lfo2) * 0.0005;
    env[i] = (0.85 + lfo1 * 20 + lfo2 * 3).clamp(0.55, 1.15);
  }

  final rnd = Random(soundId.hashCode);
  double x1a = 0, x2a = 0, y1a = 0, y2a = 0;
  double x1b = 0, x2b = 0, y1b = 0, y2b = 0;
  double lfoPhase = 0;
  double gustPhase = 0;

  double biquad(
    String type,
    double freq,
    double Q,
    double x0,
    double x1p,
    double x2p,
    double y1p,
    double y2p,
  ) {
    final w0 = 2 * pi * freq / sampleRate;
    final alpha = sin(w0) / (2 * Q);
    double b0, b1, b2, a0, a1, a2;
    switch (type) {
      case 'lowpass':
        b0 = (1 - cos(w0)) / 2;
        b1 = 1 - cos(w0);
        b2 = (1 - cos(w0)) / 2;
        a0 = 1 + alpha;
        a1 = -2 * cos(w0);
        a2 = 1 - alpha;
        break;
      case 'highpass':
        b0 = (1 + cos(w0)) / 2;
        b1 = -(1 + cos(w0));
        b2 = (1 + cos(w0)) / 2;
        a0 = 1 + alpha;
        a1 = -2 * cos(w0);
        a2 = 1 - alpha;
        break;
      case 'bandpass':
        b0 = alpha;
        b1 = 0;
        b2 = -alpha;
        a0 = 1 + alpha;
        a1 = -2 * cos(w0);
        a2 = 1 - alpha;
        break;
      default:
        b0 = 1; b1 = 0; b2 = 0; a0 = 1; a1 = 0; a2 = 0;
    }
    return (b0 / a0) * x0 +
        (b1 / a0) * x1p +
        (b2 / a0) * x2p -
        (a1 / a0) * y1p -
        (a2 / a0) * y2p;
  }


  for (int i = 0; i < totalSamples; i++) {
    final x0 = pink[i];
    double sample = 0;
    switch (soundId) {
      case 'rain':
        // 雨幕：粉噪声去掉低频隆隆、再压住残留的高频嘶鸣
        var s = biquad('highpass', 180, 0.7071, x0, x1a, x2a, y1a, y2a);
        x2a = x1a; x1a = x0; y2a = y1a; y1a = s;
        s = biquad('lowpass', 9000, 0.7071, s, x1b, x2b, y1b, y2b);
        x2b = x1b; x1b = s; y2b = y1b; y1b = s;
        sample = s * 1.9;
      case 'fire':
        // 炉膛：低频为主，几乎无高频
        var s = biquad('lowpass', 420, 1.0, x0, x1a, x2a, y1a, y2a);
        x2a = x1a; x1a = x0; y2a = y1a; y1a = s;
        s = biquad('lowpass', 420, 1.0, s, x1b, x2b, y1b, y2b);
        x2b = x1b; x1b = s; y2b = y1b; y1b = s;
        sample = s * 3.6;
      case 'ocean':
        lfoPhase += 2 * pi / (sampleRate * 8);
        final modFreq = 600 + sin(lfoPhase) * 320;
        var s = biquad('lowpass', modFreq, 0.8, x0, x1a, x2a, y1a, y2a);
        x2a = x1a; x1a = x0; y2a = y1a; y1a = s;
        s = biquad('lowpass', 1600, 0.7071, s, x1b, x2b, y1b, y2b);
        x2b = x1b; x1b = s; y2b = y1b; y1b = s;
        sample = s * (2.2 + 1.4 * sin(lfoPhase * 2));
      case 'wind':
        lfoPhase += 2 * pi / (sampleRate * 11);
        gustPhase += 2 * pi / (sampleRate * 19);
        final modFreq = 380 + sin(lfoPhase) * 200;
        var s = biquad('bandpass', modFreq, 0.30, x0, x1a, x2a, y1a, y2a);
        x2a = x1a; x1a = x0; y2a = y1a; y1a = s;
        s = biquad('lowpass', 2400, 0.7071, s, x1b, x2b, y1b, y2b);
        x2b = x1b; x1b = s; y2b = y1b; y1b = s;
        sample = s * (2.6 + 1.6 * sin(gustPhase));
      case 'forest':
        var s = biquad('highpass', 400, 0.7071, x0, x1a, x2a, y1a, y2a);
        x2a = x1a; x1a = x0; y2a = y1a; y1a = s;
        s = biquad('lowpass', 6000, 0.7071, s, x1b, x2b, y1b, y2b);
        x2b = x1b; x1b = s; y2b = y1b; y1b = s;
        sample = s * 1.6;
      case 'cafe':
        lfoPhase += (x0 - lfoPhase) * 0.02;
        var s = biquad('lowpass', 700, 0.7071, lfoPhase, x1a, x2a, y1a, y2a);
        x2a = x1a; x1a = lfoPhase; y2a = y1a; y1a = s;
        sample = s * 9.0;
      default:
        sample = x0 * 0.1;
    }
    pcm[i] = sample * env[i] * volume;
  }

  void addDroplet(int at, double amp) {
    final f = 2200 + rnd.nextDouble() * 1600;
    final len = (sampleRate * 0.02).toInt();
    for (var k = 0; k < len && at + k < totalSamples; k++) {
      final env = exp(-9.0 * k / len);
      pcm[at + k] += sin(2 * pi * f * k / sampleRate) * env * amp * volume;
    }
  }

  void addCrackle(int at, double amp) {
    final len = (sampleRate * 0.012).toInt();
    double y = 0;
    for (var k = 0; k < len && at + k < totalSamples; k++) {
      final env = exp(-7.0 * k / len);
      y = 0.75 * y + 0.25 * (rnd.nextDouble() * 2 - 1);
      pcm[at + k] += y * env * amp * volume;
    }
  }

  void addChirp(int at, double amp) {
    final len = (sampleRate * 0.13).toInt();
    var f0 = 2300 + rnd.nextDouble() * 900;
    for (var k = 0; k < len && at + k < totalSamples; k++) {
      final x = k / len;
      f0 += 60 * (x > 0.5 ? 1 : -1);
      final env = sin(pi * x) * (0.6 + 0.4 * sin(2 * pi * 7 * x));
      pcm[at + k] += sin(2 * pi * f0 * k / sampleRate) * env * amp * volume;
    }
  }

  void addClink(int at, double amp) {
    final len = (sampleRate * 0.06).toInt();
    const f = 3100.0;
    for (var k = 0; k < len && at + k < totalSamples; k++) {
      final env = exp(-14.0 * k / len);
      pcm[at + k] += sin(2 * pi * f * k / sampleRate) * env * amp * volume;
    }
  }

  int pos = 0;
  while (pos < totalSamples) {
    switch (soundId) {
      case 'rain':
        pos += (sampleRate * 0.05 + rnd.nextDouble() * sampleRate * 0.25).toInt();
        if (pos < totalSamples) addDroplet(pos, 0.35 + rnd.nextDouble() * 0.4);
      case 'fire':
        pos += (sampleRate * 0.02 + rnd.nextDouble() * sampleRate * 0.12).toInt();
        if (pos < totalSamples) {
          final amp = 0.5 + rnd.nextDouble() * 0.9;
          addCrackle(pos, amp);
          if (rnd.nextDouble() < 0.25) addCrackle(pos + 120, amp * 0.6);
        }
      case 'forest':
        pos += (sampleRate * 0.5 + rnd.nextDouble() * sampleRate * 1.6).toInt();
        if (pos < totalSamples) addChirp(pos, 0.25 + rnd.nextDouble() * 0.2);
      case 'cafe':
        pos += (sampleRate * 0.6 + rnd.nextDouble() * sampleRate * 1.8).toInt();
        if (pos < totalSamples) addClink(pos, 0.2 + rnd.nextDouble() * 0.25);
      default:
        pos += sampleRate;
    }
  }

  double maxVal = 0.001;
  for (int i = 0; i < totalSamples; i++) {
    final abs = pcm[i].abs();
    if (abs > maxVal) maxVal = abs;
  }
  final normFactor = maxVal > 0.9 ? 0.9 / maxVal : 1.0;
  final result = ByteData(totalSamples * 2);
  for (int i = 0; i < totalSamples; i++) {
    result.setInt16(
      i * 2,
      (pcm[i] * normFactor * 32767).toInt().clamp(-32768, 32767),
      Endian.little,
    );
  }
  return result.buffer.asUint8List();
}

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  AudioPlayer? _sfxPlayer;
  AudioPlayer? _ambientPlayer;
  bool _isPlaying = false;
  String _currentSound = 'none';
  double _volume = 0.5;
  bool _initialized = false;

  bool get isPlaying => _isPlaying;
  String get currentSound => _currentSound;
  double get volume => _volume;

  final List<Map<String, dynamic>> soundOptions = [
    {
      'id': 'rain',
      'name': '雨声',
      'icon': Icons.water_drop,
      'color': Colors.blue,
    },
    {
      'id': 'fire',
      'name': '炉火',
      'icon': Icons.local_fire_department,
      'color': Colors.orange,
    },
    {'id': 'ocean', 'name': '海浪', 'icon': Icons.waves, 'color': Colors.teal},
    {'id': 'wind', 'name': '微风', 'icon': Icons.air, 'color': Colors.cyan},
    {'id': 'forest', 'name': '森林', 'icon': Icons.forest, 'color': Colors.green},
    {'id': 'cafe', 'name': '咖啡馆', 'icon': Icons.coffee, 'color': Colors.brown},
  ];

  static const int _sampleRate = 44100;

  /// 仅供测试：检查合成的环境音是否非空、无 NaN、有实际能量。
  @visibleForTesting
  static Map<String, double> debugInspectNoise(String soundId, int seconds) {
    final pcm = _generateNoisePcmStatic(soundId, 0.5, seconds);
    final samples = ByteData.sublistView(pcm);
    var peak = 0.0;
    var sumSq = 0.0;
    for (var i = 0; i < samples.lengthInBytes - 1; i += 2) {
      final v = samples.getInt16(i, Endian.little) / 32768.0;
      peak = max(peak, v.abs());
      sumSq += v * v;
    }
    final n = samples.lengthInBytes ~/ 2;
    return {
      'bytes': samples.lengthInBytes.toDouble(),
      'peak': peak,
      'rms': sqrt(sumSq / (n > 0 ? n : 1)),
    };
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    _sfxPlayer = AudioPlayer();
  }

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

  Uint8List _generateTonePcm(
    double frequency,
    int durationMs, {
    double vol = 0.3,
    double attackMs = 10,
    double releaseMs = 50,
  }) {
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
      pcm.setInt16(
        i * 2,
        (sample * 32767).toInt().clamp(-32768, 32767),
        Endian.little,
      );
    }

    return pcm.buffer.asUint8List();
  }

  @visibleForTesting
  static Uint8List debugInspectChime() {
    final s = AudioService();
    return s._generateChordPcm([523.25, 659.25, 783.99, 1046.50], 200, vol: 0.22);
  }

  Uint8List _generateChordPcm(
    List<double> frequencies,
    int durationMs, {
    double vol = 0.2,
  }) {
    final totalSamples = (_sampleRate * durationMs / 1000).toInt();
    final pcm = Float64List(totalSamples);
    final attack = (_sampleRate * 0.008).toInt();

    for (var n = 0; n < frequencies.length; n++) {
      final f = frequencies[n];
      final vel = 1.0 - n * 0.18;
      final decay = 0.45 + n * 0.12;
      for (var i = attack + n * 900; i < totalSamples; i++) {
        final t = (i - attack - n * 900) / _sampleRate;
        final env = exp(-t / decay);
        pcm[i] += sin(2 * pi * f * t) * env * vol * vel;
        pcm[i] += sin(2 * pi * f * 2.01 * t) * env * vol * 0.32 * vel;
        pcm[i] += sin(2 * pi * f * 3.02 * t) * exp(-t / (decay * 0.6)) * vol * 0.14 * vel;
      }
    }

    double maxVal = 0.001;
    for (var i = 0; i < totalSamples; i++) {
      maxVal = max(maxVal, pcm[i].abs());
    }
    final norm = maxVal > 0.9 ? 0.9 / maxVal : 1.0;
    final result = ByteData(totalSamples * 2);
    for (var i = 0; i < totalSamples; i++) {
      result.setInt16(
        i * 2,
        (pcm[i] * norm * 32767).toInt().clamp(-32768, 32767),
        Endian.little,
      );
    }
    return result.buffer.asUint8List();
  }

  Future<void> playWhiteNoise(String soundId, {double volume = 0.5}) async {
    _currentSound = soundId;
    _volume = volume;
    _isPlaying = true;

    try {
      await stopWhiteNoise();
      final ok = await platformPlayWhiteNoise(soundId, volume);
      if (!ok) {
        _ambientPlayer = AudioPlayer();
        final int durationSec = kIsWeb ? 4 : 30;
        final Uint8List pcmData;
        if (kIsWeb) {
          pcmData = _generateNoisePcmStatic(soundId, volume, durationSec);
        } else {
          pcmData = await compute(
            _generateNoisePcmIsolate,
            _NoiseParams(soundId, volume, durationSec),
          );
        }
        final wavData = _generateWav(pcmData, _sampleRate, 1);
        await _ambientPlayer!.setReleaseMode(ReleaseMode.loop);
        await _ambientPlayer!.setVolume(volume);

        if (!kIsWeb) {
          try {
            final dir = await getTemporaryDirectory();
            final file = File('${dir.path}/clocker_noise.wav');
            await file.writeAsBytes(wavData, flush: true);
            await _ambientPlayer!.play(DeviceFileSource(file.path));
          } catch (e) {
            debugPrint('Temp file fallback: $e');
            await _ambientPlayer!.play(BytesSource(wavData));
          }
        } else {
          await _ambientPlayer!.play(BytesSource(wavData));
        }
      }
      debugPrint('Playing white noise: $soundId (native=${!ok})');
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  Future<void> stopWhiteNoise() async {
    _isPlaying = false;
    _currentSound = 'none';
    try {
      await platformStopWhiteNoise();
      await _ambientPlayer?.stop();
      _ambientPlayer?.dispose();
      _ambientPlayer = null;
    } catch (e) {
      debugPrint('Audio stop error: $e');
    }
    if (!kIsWeb) {
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/clocker_noise.wav');
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await platformSetNoiseVolume(_volume);
      await _ambientPlayer?.setVolume(_volume);
    } catch (e) {
      debugPrint('Volume error: $e');
    }
  }

  Future<void> playCompletionSound() async {
    try {
      final webChime = await platformPlayChime();
      if (webChime) {
        debugPrint('Completion sound: web chime');
        return;
      }
      final chord = _generateChordPcm([523.25, 659.25, 783.99, 1046.50], 1400, vol: 0.22);
      final wav = _generateWav(chord, _sampleRate, 1);
      await _sfxPlayer?.play(BytesSource(wav));
      debugPrint('Completion sound: C-E-G major chord');
    } catch (e) {
      debugPrint('Completion sound error: $e');
    }
  }

  Future<void> playDistractionSound() async {
    try {
      final pcm = _generateTonePcm(
        200,
        300,
        vol: 0.4,
        attackMs: 5,
        releaseMs: 100,
      );
      final wav = _generateWav(pcm, _sampleRate, 1);
      await _sfxPlayer?.play(BytesSource(wav));
      debugPrint('Distraction warning: 200Hz');
    } catch (e) {
      debugPrint('Distraction sound error: $e');
    }
  }

  Future<void> playAchievementSound() async {
    try {
      final a = _generateTonePcm(880, 100, vol: 0.2);
      final b = _generateTonePcm(1100, 150, vol: 0.25);
      final c = _generateTonePcm(1320, 200, vol: 0.3);
      final d = _generateTonePcm(1760, 400, vol: 0.25);
      final combined = Uint8List.fromList([...a, ...b, ...c, ...d]);
      final wav = _generateWav(combined, _sampleRate, 1);
      await _sfxPlayer?.play(BytesSource(wav));
      debugPrint('Achievement sound: ascending tones');
    } catch (e) {
      debugPrint('Achievement sound error: $e');
    }
  }

  Future<void> playTickSound() async {
    try {
      final pcm = _generateTonePcm(
        1000,
        50,
        vol: 0.15,
        attackMs: 2,
        releaseMs: 20,
      );
      final wav = _generateWav(pcm, _sampleRate, 1);
      await _sfxPlayer?.play(BytesSource(wav));
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
    _sfxPlayer?.dispose();
  }
}
