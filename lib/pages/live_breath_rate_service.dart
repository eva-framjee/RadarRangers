import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BreathEngine {
  // SINGLETON ---------------------------------------------------------
  static final BreathEngine _instance = BreathEngine._internal();
  factory BreathEngine() => _instance;
  BreathEngine._internal();

  // -------------------------------------------------------------------
  // NOTIFICATIONS
  // -------------------------------------------------------------------
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  bool notificationsInitialized = false;

  Future<void> initNotifications() async {
    if (notificationsInitialized) return;
    notificationsInitialized = true;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await notifications.initialize(settings);
  }

  Future<void> sendAlert(String msg) async {
    const androidDetails = AndroidNotificationDetails(
      'breath_alerts',
      'Breathing Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    await notifications.show(
      1,
      "Breathing Alert",
      msg,
      NotificationDetails(android: androidDetails),
    );
  }

  // -------------------------------------------------------------------
  // LIVE DATA (background)
  // -------------------------------------------------------------------
  List<FlSpot> dataPoints = [];
  double timeX = 0;

  double t = 0;            // waveform time
  double currentBR = 12;   // breathing rate shown live

  bool lowAlertSent = false;
  bool highAlertSent = false;

  Timer? timer;

  // -------------------------------------------------------------------
  // 24-HOUR AVERAGES
  // -------------------------------------------------------------------
  List<double> hourlyAverages = List.filled(24, 12);
  int samplesCollected = 0;
  double sumBR = 0;

  // -------------------------------------------------------------------
  // START ENGINE (only once)
  // -------------------------------------------------------------------
  void start() {
    if (timer != null) return; // prevents duplicate timers
    initNotifications();

    timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateBreathing();
    });
  }

  // -------------------------------------------------------------------
  // WAVE LOGIC
  // -------------------------------------------------------------------
  void _updateBreathing() {
    double breathsPerMin = 10 + sin(DateTime.now().second / 4) * 3;
    double wave = 17 + 10 * sin(t);

    t += 0.15;
    currentBR = breathsPerMin;

    // ---------- ALERT LOGIC ----------
    if (currentBR < 8 && !lowAlertSent) {
      sendAlert("Breathing too slow: ${currentBR.toInt()} bpm");
      lowAlertSent = true;
    } else if (currentBR >= 8) lowAlertSent = false;

    if (currentBR > 22 && !highAlertSent) {
      sendAlert("Breathing too fast: ${currentBR.toInt()} bpm");
      highAlertSent = true;
    } else if (currentBR <= 22) highAlertSent = false;

    // ---------- UPDATE HOURLY AVERAGE ----------
    sumBR += currentBR;
    samplesCollected++;

    if (samplesCollected == 36000) {
      hourlyAverages.removeAt(0);
      hourlyAverages.add(sumBR / samplesCollected);
      samplesCollected = 0;
      sumBR = 0;
    }

    // ---------- UPDATE WAVEFORM ----------
    dataPoints.add(FlSpot(timeX, wave));
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
  }
}
