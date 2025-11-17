import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'live_heart_rate_service.dart';

class LiveHeartWavePage extends StatefulWidget {
  const LiveHeartWavePage({super.key});

  @override
  State<LiveHeartWavePage> createState() => _LiveHeartWavePageState();
}

class _LiveHeartWavePageState extends State<LiveHeartWavePage> {
  final HeartRateService service = HeartRateService();

  // Notifications
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? waveformTimer;   // refreshes graph 10× per sec
  Timer? bpmTimer;        // refreshes BPM number 1× per sec
  double displayedBPM = 0;

  @override
  void initState() {
    super.initState();
    initNotifications();

    service.start(); // persistent HR simulation

    // GRAPH REFRESH — smooth waveform (10 Hz)
    waveformTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => setState(() {}), // redraw graph
    );

    // BPM REFRESH — updates only once per second
    bpmTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        setState(() {
          displayedBPM = service.currentBPM; // update once per sec
        });
      },
    );
  }

  @override
  void dispose() {
    waveformTimer?.cancel();
    bpmTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------
  // NOTIFICATIONS
  // ---------------------------------------------------
  Future<void> initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await notificationsPlugin.initialize(settings);
  }

  Future<void> sendAlert(String msg) async {
    const androidDetails = AndroidNotificationDetails(
      'heart_alerts',
      'Heart Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    await notificationsPlugin.show(
      0,
      "Heart Rate Alert",
      msg,
      NotificationDetails(android: androidDetails),
    );
  }

  // ---------------------------------------------------
  // ALERT LOGIC (runs every frame)
  // ---------------------------------------------------
  void checkAlerts() {
    double bpm = service.currentBPM;

    if (bpm < 40 && !service.lowAlertSent) {
      sendAlert("Heart rate too low: ${bpm.toInt()} BPM");
      service.lowAlertSent = true;
    } else if (bpm >= 40) {
      service.lowAlertSent = false;
    }

    if (bpm > 120 && !service.highAlertSent) {
      sendAlert("Heart rate too high: ${bpm.toInt()} BPM");
      service.highAlertSent = true;
    } else if (bpm <= 120) {
      service.highAlertSent = false;
    }
  }

  // ---------------------------------------------------
  // UI
  // ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    checkAlerts();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),

          // ---------------- LIVE BPM ----------------
          Text(
            "${displayedBPM.toStringAsFixed(0)} bpm", // updates once per sec
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),

          const SizedBox(height: 20),

          // ---------------- 60 SECOND WAVEFORM ----------------
          Padding(
            padding: const EdgeInsets.only(left: 40, right: 20, bottom: 20),
            child: SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minY: 40,
                  maxY: 160,
                  minX: 0,
                  maxX: 60,

                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),

                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text(
                        "Past 60 seconds",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 10,
                        getTitlesWidget: (v, m) =>
                            Text("${60 - v.toInt()}s",
                                style: const TextStyle(fontSize: 10)),
                      ),
                    ),

                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: service.dataPoints,
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.red,
                      dotData: FlDotData(show: false),
                    )
                  ],
                ),
              ),
            ),
          ),

          // ---------------- 24h AVERAGE BAR GRAPH ----------------
          const Text(
            "Average Heart Rate (past 24 hours)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                maxY: 160,
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (v, _) =>
                          Text(v.toInt().toString(), style: const TextStyle(fontSize: 8)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (i, _) =>
                          Text((i.toInt() + 1).toString(),
                              style: const TextStyle(fontSize: 8)),
                    ),
                  ),
                ),

                barGroups: List.generate(
                  24,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: service.hourlyAverages[i],
                        width: 6,
                        color: Colors.red,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
