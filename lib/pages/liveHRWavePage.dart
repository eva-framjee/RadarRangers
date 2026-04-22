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


// //CODE THAT WORKED MONDAY NIGHT

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









// //CODE THAT has better axis titles

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
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     reservedSize: 34,
//                     getTitlesWidget: (value, meta) {
//                       return Text(
//                         value.toInt().toString(),
//                         style: const TextStyle(fontSize: 10),
//                       );
//                     },
//                   ),
//                 ),
//                 bottomTitles: AxisTitles(
//                   axisNameWidget: const Text("time"),
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     reservedSize: 28,
//                     getTitlesWidget: (value, meta) {
//                       if ((value - minX).abs() < 0.6) {
//                         return const Text(
//                           "1 min ago",
//                           style: TextStyle(fontSize: 10),
//                         );
//                       }
//                       if ((value - maxX).abs() < 0.6) {
//                         return const Text(
//                           "now",
//                           style: TextStyle(fontSize: 10),
//                         );
//                       }
//                       return const SizedBox.shrink();
//                     },
//                   ),
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

//code w better graph

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
  final VitalsBleClient ble = VitalsBleClient();
  final VitalsFirestoreLogger logger = VitalsFirestoreLogger();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _uiTimer;
  Timer? _alertTimer;
  Timer? _historyTimer;

  double displayedBPM = 0;

  int minHR = 60;
  int maxHR = 100;
  bool rangeLoaded = false;

  bool lowAlertSent = false;
  bool highAlertSent = false;

  // Live graph
  static final List<FlSpot> _bpmWave = [];
  static double _t = 0.0;
  static const double _windowSeconds = 60.0;
  static const int _maxPoints = 2000;

  // Past 24h bar graph
  List<BarChartGroupData> _hourlyBarGroups = [];
  bool _historyLoaded = false;

  @override
  void initState() {
    super.initState();

    _initNotifications();
    _loadUserRange();
    _loadHourlyHeartHistory();

    _historyTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadHourlyHeartHistory();
    });

    _uiTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!mounted) return;

      final bpm = ble.currentHR;
      print("HR PAGE BPM: $bpm");

      displayedBPM = bpm;

      if (bpm > 0) {
        _t += 0.5;
        _bpmWave.add(FlSpot(_t, bpm));

        while (_bpmWave.isNotEmpty &&
            (_t - _bpmWave.first.x) > _windowSeconds) {
          _bpmWave.removeAt(0);
        }

        if (_bpmWave.length > _maxPoints) {
          _bpmWave.removeRange(0, _bpmWave.length - _maxPoints);
        }

        await logger.logHeartRate(
          uid: widget.uid,
          bpm: bpm,
          minIntervalSeconds: 5,
        );
      }

      setState(() {});
    });

    _alertTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (rangeLoaded) _checkAlerts();
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _alertTimer?.cancel();
    _historyTimer?.cancel();
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

  Future<void> _loadHourlyHeartHistory() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 24));

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('heart_data')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .orderBy('timestamp')
          .get();

      final Map<int, List<double>> hourlyBuckets = {};
      for (int i = 0; i < 24; i++) {
        hourlyBuckets[i] = [];
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final hrRaw = data['heart_rate'];
        final tsRaw = data['timestamp'];

        if (hrRaw == null || tsRaw == null) continue;
        if (tsRaw is! Timestamp) continue;

        final hr = (hrRaw as num).toDouble();
        final timestamp = tsRaw.toDate();

        final diffHours = now.difference(timestamp).inMinutes / 60.0;
        final bucketFromNow = diffHours.floor();

        if (bucketFromNow >= 0 && bucketFromNow < 24) {
          final xIndex = 23 - bucketFromNow;
          hourlyBuckets[xIndex]!.add(hr);
        }
      }

      final List<BarChartGroupData> newBarGroups = [];

      for (int i = 0; i < 24; i++) {
        final values = hourlyBuckets[i]!;
        final avg = values.isNotEmpty
            ? values.reduce((a, b) => a + b) / values.length
            : 0.0;

        newBarGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: avg,
                width: 8,
                borderRadius: BorderRadius.circular(2),
                color: Colors.red,
              ),
            ],
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _hourlyBarGroups = newBarGroups;
        _historyLoaded = true;
      });
    } catch (e) {
      print("Error loading hourly heart history: $e");
      if (!mounted) return;
      setState(() {
        _historyLoaded = true;
        _hourlyBarGroups = List.generate(
          24,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: 0,
                width: 8,
                borderRadius: BorderRadius.circular(2),
                color: Colors.red,
              ),
            ],
          ),
        );
      });
    }
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

  Widget _hourLabel(double value) {
    if (value == 0) {
      return const Text(
        "24h ago",
        style: TextStyle(fontSize: 10),
      );
    }
    if (value == 6) {
      return const Text(
        "18h ago",
        style: TextStyle(fontSize: 10),
      );
    }
    if (value == 12) {
      return const Text(
        "12h ago",
        style: TextStyle(fontSize: 10),
      );
    }
    if (value == 18) {
      return const Text(
        "6h ago",
        style: TextStyle(fontSize: 10),
      );
    }
    if (value == 23) {
      return const Text(
        "now",
        style: TextStyle(fontSize: 10),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final waveSpots = List<FlSpot>.from(_bpmWave);
    final hasWave = waveSpots.isNotEmpty;

    final minX = hasWave ? waveSpots.first.x : 0.0;
    final maxX = hasWave ? waveSpots.last.x : _windowSeconds;

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

          if (rangeLoaded)
            Text(
              "Normal range: $minHR - $maxHR bpm",
              style: const TextStyle(fontSize: 12),
            ),

          const SizedBox(height: 20),

          // LIVE HEART RATE GRAPH
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
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text("time"),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if ((value - minX).abs() < 0.6) {
                          return const Text(
                            "1 min ago",
                            style: TextStyle(fontSize: 10),
                          );
                        }
                        if ((value - maxX).abs() < 0.6) {
                          return const Text(
                            "now",
                            style: TextStyle(fontSize: 10),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
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

          const SizedBox(height: 30),

          const Text(
            "Past 24 hours",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 260,
            child: !_historyLoaded
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      BarChart(
                        BarChartData(
                          minY: 0,
                          maxY: 180,
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: true),
                          alignment: BarChartAlignment.spaceAround,
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              axisNameWidget: const Text("Avg HR (bpm)"),
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 34,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              axisNameWidget: const Text("time"),
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) {
                                  return _hourLabel(value);
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          barGroups: _hourlyBarGroups,
                        ),
                      ),

                      if (_hourlyBarGroups.every((group) =>
                          group.barRods.every((rod) => rod.toY == 0)))
                        const Center(
                          child: Text(
                            "No data yet",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}