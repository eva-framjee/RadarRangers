
// lib/pages/liveHRWavePage.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'live_heart_rate_service.dart'; // adjust path if needed

class LiveHeartWavePage extends StatefulWidget {
  final String username;  // <-- you MUST pass the username so we know which user to load

  const LiveHeartWavePage({super.key, required this.username});

  @override
  State<LiveHeartWavePage> createState() => _LiveHeartWavePageState();
}

class _LiveHeartWavePageState extends State<LiveHeartWavePage> {
  final HeartRateService service = HeartRateService();

  // Local notifications
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _waveformTimer;
  Timer? _bpmTimer;

  double displayedBPM = 0;

  // User-selected HR range
  int minHR = 60;   // default fallback
  int maxHR = 100;  // default fallback
  bool rangeLoaded = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadUserRange();

    service.start();

    _waveformTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => setState(() {}),
    );

    _bpmTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        setState(() {
          displayedBPM = service.currentBPM;
        });
        if (rangeLoaded) _checkAlerts();
      },
    );
  }

  @override
  void dispose() {
    _waveformTimer?.cancel();
    _bpmTimer?.cancel();
    super.dispose();
  }

  // ---------------- LOAD USER HEART-RATE RANGE ----------------
  Future<void> _loadUserRange() async {
    final docs = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: widget.username)
        .limit(1)
        .get();

    if (docs.docs.isNotEmpty) {
      final data = docs.docs.first.data();
      final String? range = data['normal_heart_rate'];

      if (range != null) {
        final parts = range.split("-");
        if (parts.length == 2) {
          minHR = int.tryParse(parts[0]) ?? 60;
          maxHR = int.tryParse(parts[1]) ?? 100;
        }
      }
    }

    setState(() {
      rangeLoaded = true;
    });
  }

  // ---------------- NOTIFICATIONS ----------------
  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await notificationsPlugin.initialize(settings);

    const channel = AndroidNotificationChannel(
      'heart_alerts', // must match your notification channel ID
      'Heart Alerts',
      description: 'Alerts for abnormal heart rate',
      importance: Importance.high,
    );

    final androidPlugin =
        notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      try {
        await androidPlugin.createNotificationChannel(channel);
      } catch (e) {
        print("Notification channel already exists");
      }
    }
  }


  Future<void> _sendAlert(String msg) async {
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
      const NotificationDetails(android: androidDetails),
    );
  }

  // ---------------- ALERT LOGIC USING USER RANGE ----------------
  void _checkAlerts() {
    final bpm = service.currentBPM;

    // Low alert
    if (bpm < minHR && !service.lowAlertSent) {
      _sendAlert("Heart rate too low: ${bpm.toInt()} BPM\n(Normal range: $minHR - $maxHR)");
      service.lowAlertSent = true;
    } else if (bpm >= minHR) {
      service.lowAlertSent = false;
    }

    // High alert
    if (bpm > maxHR && !service.highAlertSent) {
      _sendAlert("Heart rate too high: ${bpm.toInt()} BPM\n(Normal range: $minHR - $maxHR)");
      service.highAlertSent = true;
    } else if (bpm <= maxHR) {
      service.highAlertSent = false;
    }
  }

  // ---------------- COLOR LOGIC FOR BARS ----------------
  Color _getBarColor(double bpm) {
    if (bpm > maxHR) return Colors.red;
    if (bpm < minHR) return Colors.red;
    return Colors.green;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),

          Text(
            "${displayedBPM.toStringAsFixed(0)} bpm",
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),

          const SizedBox(height: 10),

          // HRV Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200, width: 1),
            ),
            child: Column(
              children: [
                const Text(
                  "Heart Rate Variability (last hour)",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "+/-${service.hourHRV.toStringAsFixed(1)} bpm",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Waveform
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
                        getTitlesWidget: (v, m) => Text(
                          "${60 - v.toInt()}s",
                          style: const TextStyle(fontSize: 10),
                        ),
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
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: service.dataPoints,
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.red,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 24-Hour Bar Chart
          // ---------- 24-Hour Average Bar Chart ----------
          Column(
            children: [
              const Text(
                "Average Heart Rate (past 24 hours)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    maxY: 160,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(color: Colors.black, width: 1),
                        bottom: BorderSide(color: Colors.black, width: 1),

                        // REMOVE right + top axes
                        right: BorderSide(color: Colors.transparent),
                        top: BorderSide(color: Colors.transparent),
                      ),
                    ),

                    titlesData: FlTitlesData(
                      // LEFT AXIS (keep)
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          getTitlesWidget: (v, _) =>
                              Text(v.toInt().toString(), style: const TextStyle(fontSize: 8)),
                        ),
                      ),

                      // BOTTOM AXIS (keep hours)
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (i, _) =>
                              Text((i.toInt() + 1).toString(), style: const TextStyle(fontSize: 8)),
                        ),
                      ),

                      // REMOVE RIGHT AXIS
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),

                      // REMOVE TOP AXIS
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),

                    barGroups: List.generate(
                      24,
                      (i) {
                        final bpm = service.hourlyAverages[i];
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: bpm,
                              width: 6,
                              color: _getBarColor(bpm),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),


          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
