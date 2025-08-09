// lib/utils/audio_processor.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fftea/fftea.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';


class AudioProcessor {
  final int sampleRate;
  final int fftSize;
  bool _processing = false;
  bool _stopRequested = false; // NEW

  AudioProcessor({this.sampleRate = 44100, this.fftSize = 1024});

  void stopProcessing() {
    _stopRequested = true;
  }

  Future<void> processFileAndPrintBands(String inputPath) async {
    if (_processing) return;
    _processing = true;
    _stopRequested = false;

    try {
      final outFile = await _decodeToWav(inputPath);
      if (outFile == null) return;
      await _processWavFile(outFile);
      try { await outFile.delete(); } catch (_) {}
    } catch (e, st) {
      print('AudioProcessor error: $e\n$st');
    } finally {
      _processing = false;
    }
  }

  Future<File?> _decodeToWav(String input) async {
    final tmp = await getTemporaryDirectory();
    final out = '${tmp.path}/_audio_tmp.wav';

    final cmd =
        '-y -i "${input.replaceAll('"', '\\"')}" -ac 1 -ar $sampleRate -f wav "$out"';

    final sess = await FFmpegKit.execute(cmd);
    final returnCode = await sess.getReturnCode();

    if (returnCode != null && ReturnCode.isSuccess(returnCode)) {
      return File(out);
    } else {
      print('FFmpeg decode failed. Code: $returnCode');
      return null;
    }
  }

  Future<void> _processWavFile(File wavFile) async {
    final prefs = await SharedPreferences.getInstance();
    final cols = prefs.getInt('led_cols') ?? 11;
    final rows = prefs.getInt('led_rows') ?? 14;

    final raf = await wavFile.open();
    const headerBytes = 44;
    final length = await wavFile.length();
    if (length <= headerBytes) return;
    await raf.setPosition(headerBytes);
    final bytes = (await raf.read(length - headerBytes)).buffer.asUint8List();
    await raf.close();

    final sampleCount = bytes.length ~/ 2;
    final samples = Float64List(sampleCount);
    final bd = ByteData.sublistView(bytes);
    for (var i = 0; i < sampleCount; i++) {
      samples[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
    }

    final fft = FFT(fftSize);
    final step = fftSize;
    for (var i = 0; i + step <= samples.length; i += step) {
      if (_stopRequested) {
        print('Processing stopped.');
        break;
      }

      final window = samples.sublist(i, i + step);
      _applyHanning(window);

      final freqComplex = fft.realFft(window);
      final mags = freqComplex
          .discardConjugates()
          .magnitudes()
          .toList();

      final bandAmps = _binsToBands(mags, sampleRate, fftSize, cols);
      final scaled = bandAmps.map((a) => ((a / 50.0) * rows).clamp(0.0, rows.toDouble())).toList();

      for (var b = 0; b < cols; b++) {
        print('Col ${b+1}: amp ${bandAmps[b].toStringAsFixed(2)}, rows~ ${scaled[b].toStringAsFixed(2)}');
      }
      print('---');

      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  void _applyHanning(List<double> buf) {
    final n = buf.length;
    for (var i = 0; i < n; i++) {
      buf[i] *= 0.5 - 0.5 * cos(2 * pi * i / (n - 1));
    }
  }

  List<double> _binsToBands(List<double> mags, int sampleRate, int fftSize, int bands) {
    final nyquist = sampleRate / 2.0;
    final binCount = mags.length;
    final freqPerBin = nyquist / (binCount - 1);

    final sums = List.filled(bands, 0.0);
    final counts = List.filled(bands, 0);

    for (var bin = 0; bin < binCount; bin++) {
      final freq = bin * freqPerBin;
      final idx = ((freq / nyquist) * (bands - 1)).round().clamp(0, bands - 1);
      sums[idx] += mags[bin];
      counts[idx]++;
    }
    for (var i = 0; i < bands; i++) {
      if (counts[i] > 0) sums[i] /= counts[i];
    }
    return sums;
  }
}
