// ================================
// live_heart_rate_service.dart
// BLE-backed (no dummy data)
// ================================

import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'ble_manager.dart';

class HeartRateService {
  static final HeartRateService _instance = HeartRateService._internal();
  factory HeartRateService() => _instance;
  HeartRateService._internal();

  // What your page already reads
  double currentBPM = 0;
  double hourHRV = 0; // optional; keep 0 unless you compute it later

  List<FlSpot> dataPoints = [];
  List<double> hourlyAverages = List.filled(24, 0);

  bool highAlertSent = false;
  bool lowAlertSent = false;

  StreamSubscription<int>? _bpmSub;
  StreamSubscription<List<int>>? _waveSub;

  final List<double> _waveY = [];
  final int _maxSamples = 600; // adjust to match your radar sample rate * 60s

  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    // Subscribe to BPM (if Pi provides it)
    _bpmSub = BleManager.instance.client.heartBpmStream.listen((bpm) {
      currentBPM = bpm.toDouble();
    });

    // Subscribe to waveform chunks (int16 samples)
    _waveSub = BleManager.instance.client.heartSamplesStream.listen((samples) {
      // Scale int16 samples into your chart range (40..160)
      // NOTE: adjust divisor to match your radar amplitude
      for (final s in samples) {
        final y = 100 + (s / 800.0);
        _waveY.add(y);
      }

      // cap buffer
      while (_waveY.length > _maxSamples) {
        _waveY.removeAt(0);
      }

      // rebuild spots
      dataPoints = List.generate(
        _waveY.length,
        (i) => FlSpot(i.toDouble(), _waveY[i]),
      );
    });
  }

  void dispose() {
    _bpmSub?.cancel();
    _waveSub?.cancel();
    _started = false;
  }
}
