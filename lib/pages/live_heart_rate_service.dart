import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';

class HeartRateService {
  // --------------------- SINGLETON ---------------------
  static final HeartRateService _instance = HeartRateService._internal();
  factory HeartRateService() => _instance;
  HeartRateService._internal();

  // --------------------- LIVE DATA ---------------------
  List<FlSpot> dataPoints = [];
  double timeX = 0;
  double currentBPM = 70;

  Timer? timer;

  bool running = false;

  // --------------------- ALERT FLAGS ---------------------
  bool lowAlertSent = false;
  bool highAlertSent = false;

  // --------------------- 24H DATA -----------------------
  List<double> hourlyAverages = List.filled(24, 70);  
  int samplesCollected = 0;
  double sumBPM = 0;

  // ------------------------------------------------------
  // START THE SIMULATION (only once globally)
  // ------------------------------------------------------
  void start() {
    if (running) return;
    running = true;

    timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      // realistic random variation
      double bpm = currentBPM + Random().nextDouble() * 10 - 5;

      // clamp values
      bpm = bpm.clamp(40, 160);

      currentBPM = bpm;

      // ---- 24h average handling ----
      sumBPM += currentBPM;
      samplesCollected++;

      if (samplesCollected == 3600) {
        hourlyAverages.removeAt(0);
        hourlyAverages.add(sumBPM / samplesCollected);
        samplesCollected = 0;
        sumBPM = 0;
      }

      // ---- Scroll waveform ----
      dataPoints.add(FlSpot(timeX, bpm));
      timeX += 0.1;

      if (dataPoints.length > 600) {
        dataPoints.removeAt(0);
        dataPoints = dataPoints
            .asMap()
            .entries
            .map((e) => FlSpot(e.key * 0.1, e.value.y))
            .toList();

        timeX = dataPoints.length * 0.1;
      }
    });
  }
}
