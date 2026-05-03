import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'native_audio_stub.dart' if (dart.library.html) 'web_audio_impl.dart';

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

  List<double> _biquadCoeffs(String type, double freq, double Q) {
    final w0 = 2 * pi * freq / _sampleRate;
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
        b0 = 1;
        b1 = 0;
        b2 = 0;
        a0 = 1;
        a1 = 0;
        a2 = 0;
    }

    return [b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0];
  }

  Uint8List _generateNoisePcm(
    String soundId,
    double volume,
    int durationSeconds,
  ) {
    final totalSamples = _sampleRate * durationSeconds;
    final pcm = Float64List(totalSamples);
    final random = Random();

    final noise = List.generate(
      totalSamples,
      (_) => random.nextDouble() * 2 - 1,
    );

    double x1a = 0, x2a = 0, y1a = 0, y2a = 0;
    double x1b = 0, x2b = 0, y1b = 0, y2b = 0;
    double lfoPhase = 0;

    for (int i = 0; i < totalSamples; i++) {
      final x0 = noise[i];
      double sample = 0;

      switch (soundId) {
        case 'rain':
          {
            final c = _biquadCoeffs('bandpass', 2500, 0.5);
            final y0 =
                c[0] * x0 + c[1] * x1a + c[2] * x2a - c[3] * y1a - c[4] * y2a;
            x2a = x1a;
            x1a = x0;
            y2a = y1a;
            y1a = y0;
            sample = y0;
          }
          break;

        case 'fire':
          {
            final c1 = _biquadCoeffs('lowpass', 600, 1.0);
            final s1 =
                c1[0] * x0 +
                c1[1] * x1a +
                c1[2] * x2a -
                c1[3] * y1a -
                c1[4] * y2a;
            x2a = x1a;
            x1a = x0;
            y2a = y1a;
            y1a = s1;

            final c2 = _biquadCoeffs('highpass', 80, 0.7071);
            final s2 =
                c2[0] * s1 +
                c2[1] * x1b +
                c2[2] * x2b -
                c2[3] * y1b -
                c2[4] * y2b;
            x2b = x1b;
            x1b = s1;
            y2b = y1b;
            y1b = s2;
            sample = s2;
          }
          break;

        case 'ocean':
          {
            lfoPhase += 0.12 / _sampleRate * 2 * pi;
            final modFreq = 800 + sin(lfoPhase) * 400;
            final c = _biquadCoeffs('lowpass', modFreq, 0.8);
            final y0 =
                c[0] * x0 + c[1] * x1a + c[2] * x2a - c[3] * y1a - c[4] * y2a;
            x2a = x1a;
            x1a = x0;
            y2a = y1a;
            y1a = y0;
            sample = y0;
          }
          break;

        case 'wind':
          {
            lfoPhase += 0.08 / _sampleRate * 2 * pi;
            final modFreq = 400 + sin(lfoPhase) * 300;
            final c1 = _biquadCoeffs('bandpass', modFreq, 0.3);
            final s1 =
                c1[0] * x0 +
                c1[1] * x1a +
                c1[2] * x2a -
                c1[3] * y1a -
                c1[4] * y2a;
            x2a = x1a;
            x1a = x0;
            y2a = y1a;
            y1a = s1;

            final c2 = _biquadCoeffs('lowpass', 1200, 0.7071);
            final s2 =
                c2[0] * s1 +
                c2[1] * x1b +
                c2[2] * x2b -
                c2[3] * y1b -
                c2[4] * y2b;
            x2b = x1b;
            x1b = s1;
            y2b = y1b;
            y1b = s2;
            sample = s2;
          }
          break;

        case 'forest':
          {
            final c1 = _biquadCoeffs('bandpass', 6000, 2.0);
            final s1 =
                c1[0] * x0 +
                c1[1] * x1a +
                c1[2] * x2a -
                c1[3] * y1a -
                c1[4] * y2a;
            x2a = x1a;
            x1a = x0;
            y2a = y1a;
            y1a = s1;

            final c2 = _biquadCoeffs('lowpass', 8000, 0.7071);
            final s2 =
                c2[0] * s1 +
                c2[1] * x1b +
                c2[2] * x2b -
                c2[3] * y1b -
                c2[4] * y2b;
            x2b = x1b;
            x1b = s1;
            y2b = y1b;
            y1b = s2;
            sample = s2;
          }
          break;

        case 'cafe':
          {
            final c1 = _biquadCoeffs('bandpass', 1500, 0.6);
            final s1 =
                c1[0] * x0 +
                c1[1] * x1a +
                c1[2] * x2a -
                c1[3] * y1a -
                c1[4] * y2a;
            x2a = x1a;
            x1a = x0;
            y2a = y1a;
            y1a = s1;

            final c2 = _biquadCoeffs('lowpass', 3000, 0.7071);
            final s2 =
                c2[0] * s1 +
                c2[1] * x1b +
                c2[2] * x2b -
                c2[3] * y1b -
                c2[4] * y2b;
            x2b = x1b;
            x1b = s1;
            y2b = y1b;
            y1b = s2;
            sample = s2;
          }
          break;

        default:
          sample = x0 * 0.1;
      }

      sample *= volume;
      pcm[i] = sample;
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

  Uint8List _generateChordPcm(
    List<double> frequencies,
    int durationMs, {
    double vol = 0.2,
  }) {
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
      pcm.setInt16(
        i * 2,
        (sample * 32767).toInt().clamp(-32768, 32767),
        Endian.little,
      );
    }

    return pcm.buffer.asUint8List();
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
        final pcmData = _generateNoisePcm(soundId, volume, 30);
        final wavData = _generateWav(pcmData, _sampleRate, 1);
        await _ambientPlayer!.setReleaseMode(ReleaseMode.loop);
        await _ambientPlayer!.setVolume(volume);
        await _ambientPlayer!.play(BytesSource(wavData));
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
      final chord = _generateChordPcm([523.25, 659.25, 783.99], 600, vol: 0.25);
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
