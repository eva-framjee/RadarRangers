import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'live_breath_rate_service.dart';


class LiveBreathWavePage extends StatefulWidget {
  const LiveBreathWavePage({super.key});

  @override
  State<LiveBreathWavePage> createState() => _LiveBreathWavePageState();
}

class _LiveBreathWavePageState extends State<LiveBreathWavePage> {
  final engine = BreathEngine();
  late final Timer refreshTimer;

  @override
  void initState() {
    super.initState();
    engine.start(); // STARTS ONLY ONCE, NEVER RESETS

    refreshTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    refreshTimer.cancel(); 
    super.dispose();
  }

  Widget rotated(String text) =>
      Transform.rotate(angle: -1.57, child: Text(text, style: const TextStyle(fontSize: 8)));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),

          // LIVE BREATH RATE
          Text(
            "${engine.currentBR.toStringAsFixed(0)} breaths/min",
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),

          const SizedBox(height: 20),

//60 sec waveform
          Padding(
            padding: const EdgeInsets.only(left: 40, right: 20, bottom: 20),
            child: SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 35,
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
                        interval: 5,
                        reservedSize: 35,
                        getTitlesWidget: (v, _) =>
                            Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: engine.dataPoints,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    )
                  ],
                ),
              ),
            ),
          ),

          // 24-Hr bar graph
         const Text(
          "Average Breath Rate (past 24 hours)",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              maxY: 35,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
              ),

              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(color: Colors.black, width: 1),
                  bottom: BorderSide(color: Colors.black, width: 1),
                  top: BorderSide(color: Colors.transparent),
                  right: BorderSide(color: Colors.transparent),
                ),
              ),

              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5,
                    reservedSize: 30,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 8),
                    ),
                  ),
                ),

                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    getTitlesWidget: (i, _) => Text(
                      (i.toInt() + 1).toString(),
                      style: const TextStyle(fontSize: 8),
                    ),
                  ),
                ),

                // ❌ Fully disable right axis
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                    reservedSize: 0,
                    getTitlesWidget: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // ❌ Fully disable top axis
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                    reservedSize: 0,
                    getTitlesWidget: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              barGroups: List.generate(
                24,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: engine.hourlyAverages[i],
                      width: 6,
                      color: Colors.blue,
                    ),
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
