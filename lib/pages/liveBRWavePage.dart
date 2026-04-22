// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';

// import 'vitals_ble_client.dart';
// import 'vitals_firestore_logger.dart';

// class LiveBreathWavePage extends StatefulWidget {
//   final String uid;
//   const LiveBreathWavePage({super.key, required this.uid});

//   @override
//   State<LiveBreathWavePage> createState() => _LiveBreathWavePageState();
// }

// class _LiveBreathWavePageState extends State<LiveBreathWavePage> {

//   // ✅ SAME shared BLE instance (NO reconnect)
//   final VitalsBleClient ble = VitalsBleClient();
//   final VitalsFirestoreLogger logger = VitalsFirestoreLogger();

//   Timer? _uiTimer;

//   double displayedBR = 0;

//   // Persistent graph
//   static final List<FlSpot> _brPoints = [];
//   static double _tBr = 0.0;

//   static final List<FlSpot> _sinePoints = [];
//   static double _tSine = 0.0;
//   static double _phase = 0.0;

//   static const double _windowSeconds = 60.0;
//   static const Duration _tick = Duration(milliseconds: 120);
//   static const double _tickSeconds = 0.12;

//   static const double _maxValidBR = 35.0;
//   static const double _chartMaxY = 50.0;

//   @override
//   void initState() {
//     super.initState();

//     // ✅ ONLY READ DATA (no connect here)
//     _uiTimer = Timer.periodic(_tick, (_) async {
//       if (!mounted) return;

//       final br = ble.currentBR;
//       print("BR PAGE: $br"); // 🔥 DEBUG

//       displayedBR = br;

//       // -----------------------
//       // BR GRAPH
//       // -----------------------
//       if (br > 0 && br <= _maxValidBR) {
//         _tBr += _tickSeconds;
//         _brPoints.add(FlSpot(_tBr, br));

//         while (_brPoints.isNotEmpty &&
//             (_tBr - _brPoints.first.x) > _windowSeconds) {
//           _brPoints.removeAt(0);
//         }

//         // Firestore log
//         await logger.logBreathRate(
//           uid: widget.uid,
//           br: br,
//           minIntervalSeconds: 5,
//         );
//       }

//       // -----------------------
//       // SINE WAVE
//       // -----------------------
//       final safeBr = (br > 0 && br <= _maxValidBR) ? br : 12.0;
//       final hz = safeBr / 60.0;

//       _tSine += _tickSeconds;
//       _phase += 2 * pi * hz * _tickSeconds;

//       final y = sin(_phase);
//       _sinePoints.add(FlSpot(_tSine, y));

//       while (_sinePoints.isNotEmpty &&
//           (_tSine - _sinePoints.first.x) > _windowSeconds) {
//         _sinePoints.removeAt(0);
//       }

//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     _uiTimer?.cancel();
//     super.dispose();
//   }

//   Widget _axisTitle(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Text(
//         text,
//         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {

//     final brSpots = List<FlSpot>.from(_brPoints);
//     final brMinX = brSpots.isNotEmpty ? brSpots.first.x : 0.0;
//     final brMaxX = brSpots.isNotEmpty ? brSpots.last.x : _windowSeconds;

//     final sineSpots = List<FlSpot>.from(_sinePoints);
//     final sineMinX = sineSpots.isNotEmpty ? sineSpots.first.x : 0.0;
//     final sineMaxX = sineSpots.isNotEmpty ? sineSpots.last.x : _windowSeconds;

//     return SingleChildScrollView(
//       child: Column(
//         children: [

//           const SizedBox(height: 10),

//           Text(
//             "${displayedBR.toStringAsFixed(0)} breaths/min",
//             style: const TextStyle(
//               fontSize: 42,
//               fontWeight: FontWeight.bold,
//               color: Colors.blue,
//             ),
//           ),

//           const SizedBox(height: 20),

//           // =======================
//           // BREATH RATE GRAPH
//           // =======================
//           SizedBox(
//             height: 240,
//             child: LineChart(
//               LineChartData(
//                 minX: brMinX,
//                 maxX: brMaxX,
//                 minY: 0,
//                 maxY: _chartMaxY,
//                 gridData: FlGridData(show: true),
//                 borderData: FlBorderData(show: true),
//                 titlesData: FlTitlesData(
//                   leftTitles: AxisTitles(
//                     axisNameWidget: _axisTitle("Breath rate"),
//                     sideTitles: SideTitles(showTitles: true),
//                   ),
//                   bottomTitles: AxisTitles(
//                     axisNameWidget: _axisTitle("time"),
//                     sideTitles: SideTitles(showTitles: false),
//                   ),
//                   rightTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   topTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 ),
//                 lineBarsData: [
//                   LineChartBarData(
//                     spots: brSpots,
//                     isCurved: true,
//                     color: Colors.blue,
//                     barWidth: 3,
//                     dotData: FlDotData(show: false),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 20),

//           // =======================
//           // SINE GRAPH
//           // =======================
//           SizedBox(
//             height: 240,
//             child: LineChart(
//               LineChartData(
//                 minX: sineMinX,
//                 maxX: sineMaxX,
//                 minY: -1.2,
//                 maxY: 1.2,
//                 gridData: FlGridData(show: true),
//                 borderData: FlBorderData(show: true),
//                 titlesData: FlTitlesData(
//                   leftTitles: AxisTitles(
//                     axisNameWidget: _axisTitle("Breathing (emulated)"),
//                     sideTitles: SideTitles(showTitles: true),
//                   ),
//                   bottomTitles: AxisTitles(
//                     axisNameWidget: _axisTitle("time"),
//                     sideTitles: SideTitles(showTitles: false),
//                   ),
//                   rightTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   topTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 ),
//                 lineBarsData: [
//                   LineChartBarData(
//                     spots: sineSpots,
//                     isCurved: true,
//                     color: Colors.blue,
//                     barWidth: 2,
//                     dotData: FlDotData(show: false),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


// //code that worked monday nigth

// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';

// import 'vitals_ble_client.dart';
// import 'vitals_firestore_logger.dart';

// class LiveBreathWavePage extends StatefulWidget {
//   final String uid;
//   const LiveBreathWavePage({super.key, required this.uid});

//   @override
//   State<LiveBreathWavePage> createState() => _LiveBreathWavePageState();
// }

// class _LiveBreathWavePageState extends State<LiveBreathWavePage> {

//   // ✅ SAME shared BLE instance (NO reconnect)
//   final VitalsBleClient ble = VitalsBleClient();
//   final VitalsFirestoreLogger logger = VitalsFirestoreLogger();

//   Timer? _uiTimer;

//   double displayedBR = 0;

//   // Persistent graph
//   static final List<FlSpot> _brPoints = [];
//   static double _tBr = 0.0;

//   static final List<FlSpot> _sinePoints = [];
//   static double _tSine = 0.0;
//   static double _phase = 0.0;

//   static const double _windowSeconds = 60.0;
//   static const Duration _tick = Duration(milliseconds: 120);
//   static const double _tickSeconds = 0.12;

//   static const double _maxValidBR = 35.0;
//   static const double _chartMaxY = 50.0;

//   @override
//   void initState() {
//     super.initState();

//     // ✅ ONLY READ DATA (no connect here)
//     _uiTimer = Timer.periodic(_tick, (_) async {
//       if (!mounted) return;

//       final br = ble.currentBR;
//       print("BR PAGE: $br"); // 🔥 DEBUG

//       displayedBR = br;

//       // -----------------------
//       // BR GRAPH
//       // -----------------------
//       if (br > 0 && br <= _maxValidBR) {
//         _tBr += _tickSeconds;
//         _brPoints.add(FlSpot(_tBr, br));

//         while (_brPoints.isNotEmpty &&
//             (_tBr - _brPoints.first.x) > _windowSeconds) {
//           _brPoints.removeAt(0);
//         }

//         // Firestore log
//         await logger.logBreathRate(
//           uid: widget.uid,
//           br: br,
//           minIntervalSeconds: 5,
//         );
//       }

//       // -----------------------
//       // SINE WAVE
//       // -----------------------
//       final safeBr = (br > 0 && br <= _maxValidBR) ? br : 12.0;
//       final hz = safeBr / 60.0;

//       _tSine += _tickSeconds;
//       _phase += 2 * pi * hz * _tickSeconds;

//       final y = sin(_phase);
//       _sinePoints.add(FlSpot(_tSine, y));

//       while (_sinePoints.isNotEmpty &&
//           (_tSine - _sinePoints.first.x) > _windowSeconds) {
//         _sinePoints.removeAt(0);
//       }

//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     _uiTimer?.cancel();
//     super.dispose();
//   }

//   Widget _axisTitle(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Text(
//         text,
//         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {

//     final brSpots = List<FlSpot>.from(_brPoints);
//     final brMinX = brSpots.isNotEmpty ? brSpots.first.x : 0.0;
//     final brMaxX = brSpots.isNotEmpty ? brSpots.last.x : _windowSeconds;

//     final sineSpots = List<FlSpot>.from(_sinePoints);
//     final sineMinX = sineSpots.isNotEmpty ? sineSpots.first.x : 0.0;
//     final sineMaxX = sineSpots.isNotEmpty ? sineSpots.last.x : _windowSeconds;

//     return SingleChildScrollView(
//       child: Column(
//         children: [

//           const SizedBox(height: 10),

//           Text(
//             "${displayedBR.toStringAsFixed(0)} breaths/min",
//             style: const TextStyle(
//               fontSize: 42,
//               fontWeight: FontWeight.bold,
//               color: Colors.blue,
//             ),
//           ),

//           const SizedBox(height: 20),

//           // =======================
//           // BREATH RATE GRAPH
//           // =======================
//           SizedBox(
//             height: 240,
//             child: LineChart(
//               LineChartData(
//                 minX: brMinX,
//                 maxX: brMaxX,
//                 minY: 0,
//                 maxY: _chartMaxY,
//                 gridData: FlGridData(show: true),
//                 borderData: FlBorderData(show: true),
//                 titlesData: FlTitlesData(
//                   leftTitles: AxisTitles(
//                     axisNameWidget: _axisTitle("Breath rate"),
//                     sideTitles: SideTitles(showTitles: true),
//                   ),
//                   bottomTitles: AxisTitles(
//                     axisNameWidget: _axisTitle("time"),
//                     sideTitles: SideTitles(showTitles: false),
//                   ),
//                   rightTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   topTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 ),
//                 lineBarsData: [
//                   LineChartBarData(
//                     spots: brSpots,
//                     isCurved: true,
//                     color: Colors.blue,
//                     barWidth: 3,
//                     dotData: FlDotData(show: false),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 20),

//           // =======================
//           // SINE GRAPH
//           // =======================
//           SizedBox(
//             height: 240,
//             child: LineChart(
//               LineChartData(
//                 minX: sineMinX,
//                 maxX: sineMaxX,
//                 minY: -1.2,
//                 maxY: 1.2,
//                 gridData: FlGridData(show: true),
//                 borderData: FlBorderData(show: true),
//                 titlesData: FlTitlesData(
//                   leftTitles: AxisTitles(
//                     axisNameWidget: _axisTitle("Breathing (emulated)"),
//                     sideTitles: SideTitles(showTitles: true),
//                   ),
//                   bottomTitles: AxisTitles(
//                     axisNameWidget: _axisTitle("time"),
//                     sideTitles: SideTitles(showTitles: false),
//                   ),
//                   rightTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   topTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 ),
//                 lineBarsData: [
//                   LineChartBarData(
//                     spots: sineSpots,
//                     isCurved: true,
//                     color: Colors.blue,
//                     barWidth: 2,
//                     dotData: FlDotData(show: false),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


// code that worked 4/20

//code that worked monday nigth

// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';

// import 'vitals_ble_client.dart';
// import 'vitals_firestore_logger.dart';

// class LiveBreathWavePage extends StatefulWidget {
//   final String uid;
//   const LiveBreathWavePage({super.key, required this.uid});

//   @override
//   State<LiveBreathWavePage> createState() => _LiveBreathWavePageState();
// }

// class _LiveBreathWavePageState extends State<LiveBreathWavePage> {
//   // ✅ SAME shared BLE instance (NO reconnect)
//   final VitalsBleClient ble = VitalsBleClient();
//   final VitalsFirestoreLogger logger = VitalsFirestoreLogger();

//   Timer? _uiTimer;

//   double displayedBR = 0;

//   // Persistent graph
//   static final List<FlSpot> _brPoints = [];
//   static double _tBr = 0.0;

//   static final List<FlSpot> _sinePoints = [];
//   static double _tSine = 0.0;
//   static double _phase = 0.0;

//   static const double _windowSeconds = 60.0;
//   static const Duration _tick = Duration(milliseconds: 120);
//   static const double _tickSeconds = 0.12;

//   static const double _maxValidBR = 35.0;
//   static const double _chartMaxY = 50.0;

//   @override
//   void initState() {
//     super.initState();

//     // ✅ ONLY READ DATA (no connect here)
//     _uiTimer = Timer.periodic(_tick, (_) async {
//       if (!mounted) return;

//       final br = ble.currentBR;
//       print("BR PAGE: $br"); // 🔥 DEBUG

//       displayedBR = br;

//       // -----------------------
//       // BR GRAPH
//       // -----------------------
//       if (br > 0 && br <= _maxValidBR) {
//         _tBr += _tickSeconds;
//         _brPoints.add(FlSpot(_tBr, br));

//         while (_brPoints.isNotEmpty &&
//             (_tBr - _brPoints.first.x) > _windowSeconds) {
//           _brPoints.removeAt(0);
//         }

//         // Firestore log
//         await logger.logBreathRate(
//           uid: widget.uid,
//           br: br,
//           minIntervalSeconds: 5,
//         );
//       }

//       // -----------------------
//       // SINE WAVE
//       // -----------------------
//       final safeBr = (br > 0 && br <= _maxValidBR) ? br : 12.0;
//       final hz = safeBr / 60.0;

//       _tSine += _tickSeconds;
//       _phase += 2 * pi * hz * _tickSeconds;

//       final y = sin(_phase);
//       _sinePoints.add(FlSpot(_tSine, y));

//       while (_sinePoints.isNotEmpty &&
//           (_tSine - _sinePoints.first.x) > _windowSeconds) {
//         _sinePoints.removeAt(0);
//       }

//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     _uiTimer?.cancel();
//     super.dispose();
//   }

//   Widget _axisTitle(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Text(
//         text,
//         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final brSpots = List<FlSpot>.from(_brPoints);
//     final brMinX = brSpots.isNotEmpty ? brSpots.first.x : 0.0;
//     final brMaxX = brSpots.isNotEmpty ? brSpots.last.x : _windowSeconds;

//     final sineSpots = List<FlSpot>.from(_sinePoints);
//     final sineMinX = sineSpots.isNotEmpty ? sineSpots.first.x : 0.0;
//     final sineMaxX = sineSpots.isNotEmpty ? sineSpots.last.x : _windowSeconds;

//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           const SizedBox(height: 10),
//           Text(
//             "${displayedBR.toStringAsFixed(0)} breaths/min",
//             style: const TextStyle(
//               fontSize: 42,
//               fontWeight: FontWeight.bold,
//               color: Colors.blue,
//             ),
//           ),
//           const SizedBox(height: 20),

//           // =======================
//           // BREATH RATE GRAPH
//           // =======================
//           SizedBox(
//             height: 240,
//             child: LineChart(
//               LineChartData(
//                 minX: brMinX,
//                 maxX: brMaxX,
//                 minY: 0,
//                 maxY: _chartMaxY,
//                 gridData: FlGridData(show: true),
//                 borderData: FlBorderData(show: true),
//                 titlesData: FlTitlesData(
//                   leftTitles: AxisTitles(
//                     axisNameWidget: _axisTitle("Breath rate"),
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 34,
//                       getTitlesWidget: (value, meta) {
//                         return Text(
//                           value.toInt().toString(),
//                           style: const TextStyle(fontSize: 10),
//                         );
//                       },
//                     ),
//                   ),
//                   bottomTitles: AxisTitles(
//                     axisNameWidget: _axisTitle("time"),
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 28,
//                       getTitlesWidget: (value, meta) {
//                         if ((value - brMinX).abs() < 0.6) {
//                           return const Text(
//                             "1 min ago",
//                             style: TextStyle(fontSize: 10),
//                           );
//                         }
//                         if ((value - brMaxX).abs() < 0.6) {
//                           return const Text(
//                             "now",
//                             style: TextStyle(fontSize: 10),
//                           );
//                         }
//                         return const SizedBox.shrink();
//                       },
//                     ),
//                   ),
//                   rightTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   topTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 ),
//                 lineBarsData: [
//                   LineChartBarData(
//                     spots: brSpots,
//                     isCurved: true,
//                     color: Colors.blue,
//                     barWidth: 3,
//                     dotData: FlDotData(show: false),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 20),

//           // =======================
//           // SINE GRAPH
//           // =======================
//           SizedBox(
//             height: 240,
//             child: LineChart(
//               LineChartData(
//                 minX: sineMinX,
//                 maxX: sineMaxX,
//                 minY: -1.2,
//                 maxY: 1.2,
//                 gridData: FlGridData(show: true),
//                 borderData: FlBorderData(show: true),
//                 titlesData: FlTitlesData(
//                   leftTitles: AxisTitles(
//                     axisNameWidget: _axisTitle("Breathing (emulated)"),
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 34,
//                       getTitlesWidget: (value, meta) {
//                         return Text(
//                           value.toStringAsFixed(1),
//                           style: const TextStyle(fontSize: 10),
//                         );
//                       },
//                     ),
//                   ),
//                   bottomTitles: AxisTitles(
//                     axisNameWidget: _axisTitle("time"),
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 28,
//                       getTitlesWidget: (value, meta) {
//                         if ((value - sineMinX).abs() < 0.6) {
//                           return const Text(
//                             "1 min ago",
//                             style: TextStyle(fontSize: 10),
//                           );
//                         }
//                         if ((value - sineMaxX).abs() < 0.6) {
//                           return const Text(
//                             "now",
//                             style: TextStyle(fontSize: 10),
//                           );
//                         }
//                         return const SizedBox.shrink();
//                       },
//                     ),
//                   ),
//                   rightTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   topTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 ),
//                 lineBarsData: [
//                   LineChartBarData(
//                     spots: sineSpots,
//                     isCurved: true,
//                     color: Colors.blue,
//                     barWidth: 2,
//                     dotData: FlDotData(show: false),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


//code with better grajphs

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'vitals_ble_client.dart';
import 'vitals_firestore_logger.dart';

class LiveBreathWavePage extends StatefulWidget {
  final String uid;
  const LiveBreathWavePage({super.key, required this.uid});

  @override
  State<LiveBreathWavePage> createState() => _LiveBreathWavePageState();
}

class _LiveBreathWavePageState extends State<LiveBreathWavePage> {
  // ✅ SAME shared BLE instance (NO reconnect)
  final VitalsBleClient ble = VitalsBleClient();
  final VitalsFirestoreLogger logger = VitalsFirestoreLogger();

  Timer? _uiTimer;
  Timer? _historyTimer;

  double displayedBR = 0;

  // Persistent graph
  static final List<FlSpot> _brPoints = [];
  static double _tBr = 0.0;

  static final List<FlSpot> _sinePoints = [];
  static double _tSine = 0.0;
  static double _phase = 0.0;

  static const double _windowSeconds = 60.0;
  static const Duration _tick = Duration(milliseconds: 120);
  static const double _tickSeconds = 0.12;

  static const double _maxValidBR = 35.0;
  static const double _chartMaxY = 50.0;

  // Past 24h bar graph
  List<BarChartGroupData> _hourlyBarGroups = [];
  bool _historyLoaded = false;

  @override
  void initState() {
    super.initState();

    _loadHourlyBreathHistory();

    _historyTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadHourlyBreathHistory();
    });

    // ✅ ONLY READ DATA (no connect here)
    _uiTimer = Timer.periodic(_tick, (_) async {
      if (!mounted) return;

      final br = ble.currentBR;
      print("BR PAGE: $br"); // 🔥 DEBUG

      displayedBR = br;

      // -----------------------
      // BR GRAPH
      // -----------------------
      if (br > 0 && br <= _maxValidBR) {
        _tBr += _tickSeconds;
        _brPoints.add(FlSpot(_tBr, br));

        while (_brPoints.isNotEmpty &&
            (_tBr - _brPoints.first.x) > _windowSeconds) {
          _brPoints.removeAt(0);
        }

        // Firestore log
        await logger.logBreathRate(
          uid: widget.uid,
          br: br,
          minIntervalSeconds: 5,
        );
      }

      // -----------------------
      // SINE WAVE
      // -----------------------
      final safeBr = (br > 0 && br <= _maxValidBR) ? br : 12.0;
      final hz = safeBr / 60.0;

      _tSine += _tickSeconds;
      _phase += 2 * pi * hz * _tickSeconds;

      final y = sin(_phase);
      _sinePoints.add(FlSpot(_tSine, y));

      while (_sinePoints.isNotEmpty &&
          (_tSine - _sinePoints.first.x) > _windowSeconds) {
        _sinePoints.removeAt(0);
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _historyTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHourlyBreathHistory() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 24));

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('breath_data')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .orderBy('timestamp')
          .get();

      final Map<int, List<double>> hourlyBuckets = {};
      for (int i = 0; i < 24; i++) {
        hourlyBuckets[i] = [];
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final brRaw = data['breath_rate'];
        final tsRaw = data['timestamp'];

        if (brRaw == null || tsRaw == null) continue;
        if (tsRaw is! Timestamp) continue;

        final br = (brRaw as num).toDouble();
        final timestamp = tsRaw.toDate();

        final diffHours = now.difference(timestamp).inMinutes / 60.0;
        final bucketFromNow = diffHours.floor();

        if (bucketFromNow >= 0 && bucketFromNow < 24) {
          final xIndex = 23 - bucketFromNow;
          hourlyBuckets[xIndex]!.add(br);
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
                color: Colors.blue,
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
      print("Error loading hourly breath history: $e");
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
                color: Colors.blue,
              ),
            ],
          ),
        );
      });
    }
  }

  Widget _axisTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
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
    final brSpots = List<FlSpot>.from(_brPoints);
    final brMinX = brSpots.isNotEmpty ? brSpots.first.x : 0.0;
    final brMaxX = brSpots.isNotEmpty ? brSpots.last.x : _windowSeconds;

    final sineSpots = List<FlSpot>.from(_sinePoints);
    final sineMinX = sineSpots.isNotEmpty ? sineSpots.first.x : 0.0;
    final sineMaxX = sineSpots.isNotEmpty ? sineSpots.last.x : _windowSeconds;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            "${displayedBR.toStringAsFixed(0)} breaths/min",
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 20),

          // =======================
          // BREATH RATE GRAPH
          // =======================
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minX: brMinX,
                maxX: brMaxX,
                minY: 0,
                maxY: _chartMaxY,
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: _axisTitle("Breath rate"),
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
                    axisNameWidget: _axisTitle("time"),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if ((value - brMinX).abs() < 0.6) {
                          return const Text(
                            "1 min ago",
                            style: TextStyle(fontSize: 10),
                          );
                        }
                        if ((value - brMaxX).abs() < 0.6) {
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
                    spots: brSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // =======================
          // SINE GRAPH
          // =======================
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minX: sineMinX,
                maxX: sineMaxX,
                minY: -1.2,
                maxY: 1.2,
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: _axisTitle("Breathing (emulated)"),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: _axisTitle("time"),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if ((value - sineMinX).abs() < 0.6) {
                          return const Text(
                            "1 min ago",
                            style: TextStyle(fontSize: 10),
                          );
                        }
                        if ((value - sineMaxX).abs() < 0.6) {
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
                    spots: sineSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
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
                          maxY: 40,
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: true),
                          alignment: BarChartAlignment.spaceAround,
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              axisNameWidget: const Text("Avg BR"),
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
                      if (_hourlyBarGroups.every(
                        (group) => group.barRods.every((rod) => rod.toY == 0),
                      ))
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