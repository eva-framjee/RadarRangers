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


//code that worked monday nigth

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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

  @override
  void initState() {
    super.initState();

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
    super.dispose();
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
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: _axisTitle("time"),
                    sideTitles: SideTitles(showTitles: false),
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
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: _axisTitle("time"),
                    sideTitles: SideTitles(showTitles: false),
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
        ],
      ),
    );
  }
}