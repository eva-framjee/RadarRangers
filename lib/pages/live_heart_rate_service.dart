import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';

class HeartRateService {
  // -------- SINGLETON --------
  static final HeartRateService _instance = HeartRateService._internal();
  factory HeartRateService() => _instance;
  HeartRateService._internal();

  // -------- DATA --------
  double currentBPM = 80;
  double hourHRV = 7.0;  // always non-zero

  List<FlSpot> dataPoints = [];
  List<double> hourlyAverages = List.filled(24, 75);

  bool highAlertSent = false;
  bool lowAlertSent = false;

  Timer? _bpmTimer;      // updates every second
  Timer? _hrvTimer;      // updates once per hour
  int _timeCounter = 0;

  final Random _rand = Random();

  // -------- START SERVICE --------
  void start() {
    // Prevent duplicate timers
    _bpmTimer?.cancel();
    _hrvTimer?.cancel();

    // BPM updates every second
    _bpmTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateBPM();
      _updateGraph();
    });

    // HRV updates once every hour
    _hrvTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _updateHRV();
    });
  }

  // -------- BPM: ±1 per second (40–120) --------
  void _updateBPM() {
    int change = _rand.nextBool() ? 1 : -1;
    currentBPM += change;

    if (currentBPM < 40) currentBPM = 40;
    if (currentBPM > 120) currentBPM = 120;
  }

  // -------- Graph: 60 seconds --------
  void _updateGraph() {
    dataPoints.add(FlSpot(_timeCounter.toDouble(), currentBPM));

    if (dataPoints.length > 60) {
      dataPoints.removeAt(0);

      for (int i = 0; i < dataPoints.length; i++) {
        dataPoints[i] = FlSpot(i.toDouble(), dataPoints[i].y);
      }
    }

    _timeCounter++;
  }

  // -------- HRV: update once per hour --------
  void _updateHRV() {
    // slow drift, realistic
    double drift = (_rand.nextDouble() * 0.8) - 0.4;  // -0.4 to +0.4

    hourHRV += drift;

    if (hourHRV < 4) hourHRV = 4;
    if (hourHRV > 12) hourHRV = 12;
  }

  void dispose() {
    _bpmTimer?.cancel();
    _hrvTimer?.cancel();
  }
}
