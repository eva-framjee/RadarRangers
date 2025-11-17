import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ThreeWeeksAgoPageBR extends StatefulWidget {
  final String uid;
  const ThreeWeeksAgoPageBR({super.key, required this.uid});

  @override
  State<ThreeWeeksAgoPageBR> createState() => _ThreeWeeksAgoPageStateBR();
}

class _ThreeWeeksAgoPageStateBR extends State<ThreeWeeksAgoPageBR> {
  List<double> dailyAverages = List.filled(7, 0);

  late DateTime startDate;
  late DateTime endDate;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    DateTime now = DateTime.now();

    /// 3 weeks ago 28-21
    startDate = now.subtract(const Duration(days: 28));
    endDate = now.subtract(const Duration(days: 21));

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.uid)
        .collection("breath_data")
        .where("timestamp", isGreaterThan: startDate)
        .where("timestamp", isLessThan: endDate)
        .orderBy("timestamp")
        .get();

    List<List<double>> buckets = List.generate(7, (_) => []);

    for (var doc in snapshot.docs) {
      DateTime ts = (doc["timestamp"] as Timestamp).toDate();
      int dayIndex = ts.difference(startDate).inDays.clamp(0, 6);
      double br = (doc["breath_rate"] as num).toDouble();
      buckets[dayIndex].add(br);
    }

    List<double> averages = buckets.map((list) {
      if (list.isEmpty) return 0.0;
      return list.reduce((a, b) => a + b) / list.length;
    }).toList();

    setState(() => dailyAverages = averages);
  }

  String formatRange(DateTime s, DateTime e) {
    final formatter = DateFormat("MMM d");
    return "${formatter.format(s)} - ${formatter.format(e)}";
  }

  @override
  Widget build(BuildContext context) {
    String rangeText = formatRange(startDate, endDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("3 Weeks Ago (Daily Avg)"),
        backgroundColor: Color.fromARGB(255, 172, 198, 170),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            /// ⭐ TOP HEADING ⭐
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rangeText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Breath per minute weekly average",
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ⭐ BAR CHART ⭐
            Expanded(
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 40,

                  /// --- BAR GROUPS ---
                  barGroups: List.generate(7, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: dailyAverages[i],
                          color: Colors.green,
                          width: 18,
                        ),
                      ],
                    );
                  }),

                  /// --- TITLES ---
                  titlesData: FlTitlesData(

                    /// Y-AXIS numbers only (0,5,10,...40)
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),

                    /// Bottom X-axis titles
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            "Day ${value.toInt() + 1}",
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),

                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),

                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
