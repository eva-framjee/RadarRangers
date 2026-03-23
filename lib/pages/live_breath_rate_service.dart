// ================================
// live_breath_rate_service.dart
// BLE-backed (no dummy data)
// ================================

import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'ble_manager.dart';

class BreathEngine {
  static final BreathEngine _instance = BreathEngine._internal();
  factory BreathEngine() => _instance;
  BreathEngine._internal();

  double currentBR = 0;

  List<FlSpot> dataPoints = [];
  List<double> hourlyAverages = List.filled(24, 0);

  bool lowAlertSent = false;
  bool highAlertSent = false;

  StreamSubscription<int>? _brSub;
  StreamSubscription<List<int>>? _waveSub;

  final List<double> _waveY = [];
  final int _maxSamples = 600; // adjust to match your radar sample rate * 60s

  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    // Subscribe to BRPM (if Pi provides it)
    _brSub = BleManager.instance.client.breathBpmStream.listen((brpm) {
      currentBR = brpm.toDouble();
    });

    // Subscribe to breath waveform chunks (int16 samples)
    _waveSub = BleManager.instance.client.breathSamplesStream.listen((samples) {
      // Scale into your chart range (0..35)
      // NOTE: adjust divisor to match your radar amplitude
      for (final s in samples) {
        final y = 17 + (s / 1200.0);
        _waveY.add(y);
      }

      while (_waveY.length > _maxSamples) {
        _waveY.removeAt(0);
      }

      dataPoints = List.generate(
        _waveY.length,
        (i) => FlSpot(i.toDouble(), _waveY[i]),
      );
    });
  }

  void dispose() {
    _brSub?.cancel();
    _waveSub?.cancel();
    _started = false;
  }
}
