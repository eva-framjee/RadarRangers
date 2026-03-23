// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// import 'vitals_ble_client.dart';
// import 'vitals_firestore_logger.dart';

// class LiveHeartWavePage extends StatefulWidget {
//   final String uid;
//   const LiveHeartWavePage({super.key, required this.uid});

//   @override
//   State<LiveHeartWavePage> createState() => _LiveHeartWavePageState();
// }

// class _LiveHeartWavePageState extends State<LiveHeartWavePage> {

//   // ✅ SAME shared BLE instance (DO NOT reconnect)
//   final VitalsBleClient ble = VitalsBleClient();

//   final VitalsFirestoreLogger logger = VitalsFirestoreLogger();

//   final FlutterLocalNotificationsPlugin notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   Timer? _uiTimer;
//   Timer? _alertTimer;

//   double displayedBPM = 0;

//   int minHR = 60;
//   int maxHR = 100;
//   bool rangeLoaded = false;

//   bool lowAlertSent = false;
//   bool highAlertSent = false;

//   // Persistent graph
//   static final List<FlSpot> _bpmWave = [];
//   static double _t = 0.0;
//   static const double _windowSeconds = 60.0;
//   static const int _maxPoints = 2000;

//   @override
//   void initState() {
//     super.initState();

//     _initNotifications();
//     _loadUserRange();

//     // ✅ ONLY READ DATA (no BLE connect here)
//     _uiTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
//       if (!mounted) return;

//       final bpm = ble.currentHR;
//       print("HR PAGE BPM: $bpm"); // 🔥 DEBUG

//       displayedBPM = bpm;

//       if (bpm > 0) {
//         _t += 0.5;
//         _bpmWave.add(FlSpot(_t, bpm));

//         // rolling window
//         while (_bpmWave.isNotEmpty &&
//             (_t - _bpmWave.first.x) > _windowSeconds) {
//           _bpmWave.removeAt(0);
//         }

//         // safety cap
//         if (_bpmWave.length > _maxPoints) {
//           _bpmWave.removeRange(0, _bpmWave.length - _maxPoints);
//         }

//         // Firestore logging
//         await logger.logHeartRate(
//           uid: widget.uid,
//           bpm: bpm,
//           minIntervalSeconds: 5,
//         );
//       }

//       setState(() {});
//     });

//     // Alerts
//     _alertTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (!mounted) return;
//       if (rangeLoaded) _checkAlerts();
//     });
//   }

//   @override
//   void dispose() {
//     _uiTimer?.cancel();
//     _alertTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _loadUserRange() async {
//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.uid)
//           .get();

//       final data = doc.data();
//       final String? range = data?['normal_heart_rate'];

//       if (range != null) {
//         final parts = range.split("-");
//         if (parts.length == 2) {
//           minHR = int.tryParse(parts[0].trim()) ?? 60;
//           maxHR = int.tryParse(parts[1].trim()) ?? 100;
//         }
//       }
//     } catch (_) {}

//     if (!mounted) return;
//     setState(() => rangeLoaded = true);
//   }

//   Future<void> _initNotifications() async {
//     const android = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const settings = InitializationSettings(android: android);

//     await notificationsPlugin.initialize(settings);

//     const channel = AndroidNotificationChannel(
//       'heart_alerts',
//       'Heart Alerts',
//       description: 'Alerts for abnormal heart rate',
//       importance: Importance.high,
//     );

//     final androidPlugin = notificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>();

//     if (androidPlugin != null) {
//       try {
//         await androidPlugin.createNotificationChannel(channel);
//       } catch (_) {}
//     }
//   }

//   Future<void> _sendAlert(String msg) async {
//     const androidDetails = AndroidNotificationDetails(
//       'heart_alerts',
//       'Heart Alerts',
//       importance: Importance.max,
//       priority: Priority.high,
//     );

//     await notificationsPlugin.show(
//       0,
//       "Heart Rate Alert",
//       msg,
//       const NotificationDetails(android: androidDetails),
//     );
//   }

//   void _checkAlerts() {
//     final bpm = ble.currentHR;
//     if (bpm <= 0) return;

//     if (bpm < minHR && !lowAlertSent) {
//       _sendAlert("Low HR: ${bpm.toInt()} BPM");
//       lowAlertSent = true;
//     } else if (bpm >= minHR) {
//       lowAlertSent = false;
//     }

//     if (bpm > maxHR && !highAlertSent) {
//       _sendAlert("High HR: ${bpm.toInt()} BPM");
//       highAlertSent = true;
//     } else if (bpm <= maxHR) {
//       highAlertSent = false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {

//     final waveSpots = List<FlSpot>.from(_bpmWave);
//     final hasWave = waveSpots.isNotEmpty;

//     final minX = hasWave ? waveSpots.first.x : 0.0;
//     final maxX = hasWave ? waveSpots.last.x : _windowSeconds;

//     return Column(
//       children: [

//         const SizedBox(height: 10),

//         Text(
//           "${displayedBPM.toStringAsFixed(0)} bpm",
//           style: const TextStyle(
//             fontSize: 42,
//             fontWeight: FontWeight.bold,
//             color: Colors.red,
//           ),
//         ),

//         const SizedBox(height: 10),

//         if (rangeLoaded)
//           Text(
//             "Normal range: $minHR - $maxHR bpm",
//             style: const TextStyle(fontSize: 12),
//           ),

//         const SizedBox(height: 20),

//         SizedBox(
//           height: 300,
//           child: LineChart(
//             LineChartData(
//               minX: minX,
//               maxX: maxX,
//               minY: 0,
//               maxY: 250,
//               gridData: FlGridData(show: true),
//               borderData: FlBorderData(show: true),
//               titlesData: FlTitlesData(
//                 leftTitles: AxisTitles(
//                   axisNameWidget: const Text("Heart rate (bpm)"),
//                   sideTitles: SideTitles(showTitles: true),
//                 ),
//                 bottomTitles: AxisTitles(
//                   axisNameWidget: const Text("time"),
//                   sideTitles: SideTitles(showTitles: false),
//                 ),
//                 rightTitles:
//                     AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 topTitles:
//                     AxisTitles(sideTitles: SideTitles(showTitles: false)),
//               ),
//               lineBarsData: [
//                 LineChartBarData(
//                   spots: waveSpots,
//                   isCurved: true,
//                   color: Colors.red,
//                   barWidth: 3,
//                   dotData: FlDotData(show: false),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }


//CODE THAT WORKED MONDAY NIGHT

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'vitals_ble_client.dart';
import 'vitals_firestore_logger.dart';

class LiveHeartWavePage extends StatefulWidget {
  final String uid;
  const LiveHeartWavePage({super.key, required this.uid});

  @override
  State<LiveHeartWavePage> createState() => _LiveHeartWavePageState();
}

class _LiveHeartWavePageState extends State<LiveHeartWavePage> {

  // ✅ SAME shared BLE instance (DO NOT reconnect)
  final VitalsBleClient ble = VitalsBleClient();

  final VitalsFirestoreLogger logger = VitalsFirestoreLogger();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _uiTimer;
  Timer? _alertTimer;

  double displayedBPM = 0;

  int minHR = 60;
  int maxHR = 100;
  bool rangeLoaded = false;

  bool lowAlertSent = false;
  bool highAlertSent = false;

  // Persistent graph
  static final List<FlSpot> _bpmWave = [];
  static double _t = 0.0;
  static const double _windowSeconds = 60.0;
  static const int _maxPoints = 2000;

  @override
  void initState() {
    super.initState();

    _initNotifications();
    _loadUserRange();

    // ✅ ONLY READ DATA (no BLE connect here)
    _uiTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!mounted) return;

      final bpm = ble.currentHR;
      print("HR PAGE BPM: $bpm"); // 🔥 DEBUG

      displayedBPM = bpm;

      if (bpm > 0) {
        _t += 0.5;
        _bpmWave.add(FlSpot(_t, bpm));

        // rolling window
        while (_bpmWave.isNotEmpty &&
            (_t - _bpmWave.first.x) > _windowSeconds) {
          _bpmWave.removeAt(0);
        }

        // safety cap
        if (_bpmWave.length > _maxPoints) {
          _bpmWave.removeRange(0, _bpmWave.length - _maxPoints);
        }

        // Firestore logging
        await logger.logHeartRate(
          uid: widget.uid,
          bpm: bpm,
          minIntervalSeconds: 5,
        );
      }

      setState(() {});
    });

    // Alerts
    _alertTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (rangeLoaded) _checkAlerts();
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _alertTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserRange() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      final data = doc.data();
      final String? range = data?['normal_heart_rate'];

      if (range != null) {
        final parts = range.split("-");
        if (parts.length == 2) {
          minHR = int.tryParse(parts[0].trim()) ?? 60;
          maxHR = int.tryParse(parts[1].trim()) ?? 100;
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => rangeLoaded = true);
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await notificationsPlugin.initialize(settings);

    const channel = AndroidNotificationChannel(
      'heart_alerts',
      'Heart Alerts',
      description: 'Alerts for abnormal heart rate',
      importance: Importance.high,
    );

    final androidPlugin = notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      try {
        await androidPlugin.createNotificationChannel(channel);
      } catch (_) {}
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

  void _checkAlerts() {
    final bpm = ble.currentHR;
    if (bpm <= 0) return;

    if (bpm < minHR && !lowAlertSent) {
      _sendAlert("Low HR: ${bpm.toInt()} BPM");
      lowAlertSent = true;
    } else if (bpm >= minHR) {
      lowAlertSent = false;
    }

    if (bpm > maxHR && !highAlertSent) {
      _sendAlert("High HR: ${bpm.toInt()} BPM");
      highAlertSent = true;
    } else if (bpm <= maxHR) {
      highAlertSent = false;
    }
  }

  @override
  Widget build(BuildContext context) {

    final waveSpots = List<FlSpot>.from(_bpmWave);
    final hasWave = waveSpots.isNotEmpty;

    final minX = hasWave ? waveSpots.first.x : 0.0;
    final maxX = hasWave ? waveSpots.last.x : _windowSeconds;

    return Column(
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

        if (rangeLoaded)
          Text(
            "Normal range: $minHR - $maxHR bpm",
            style: const TextStyle(fontSize: 12),
          ),

        const SizedBox(height: 20),

        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: 0,
              maxY: 250,
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: const Text("Heart rate (bpm)"),
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: const Text("time"),
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: waveSpots,
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}