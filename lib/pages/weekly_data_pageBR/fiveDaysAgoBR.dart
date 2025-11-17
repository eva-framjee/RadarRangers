import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class FiveDaysAgoPageBR extends StatefulWidget {
  final String uid;
  const FiveDaysAgoPageBR({super.key, required this.uid});

  @override
  State<FiveDaysAgoPageBR> createState() => _FiveDaysAgoPageStateBR();
}

class _FiveDaysAgoPageStateBR extends State<FiveDaysAgoPageBR> {
  List<double> hourlyAverages = List.filled(24, 0);
  late DateTime dayShown;

  @override
  void initState() {
    super.initState();
    dayShown = DateTime.now().subtract(const Duration(days: 5));
    fetchFiveDaysAgoDataBR();
  }

  Future<void> fetchFiveDaysAgoDataBR() async {
    DateTime now = DateTime.now();
    DateTime start = now.subtract(const Duration(days: 5));
    DateTime end = now.subtract(const Duration(days: 4));

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.uid)
        .collection("breath_data")
        .where("timestamp", isGreaterThan: start)
        .where("timestamp", isLessThan: end)
        .orderBy("timestamp")
        .get();

    List<List<double>> buckets = List.generate(24, (_) => []);

    for (var doc in snapshot.docs) {
      DateTime ts = (doc["timestamp"] as Timestamp).toDate();
      int hour = ts.hour;
      double hr = (doc["breath_rate"] as num).toDouble();
      buckets[hour].add(hr);
    }

    List<double> averages = buckets.map((hourList) {
      if (hourList.isEmpty) return 0.0;
      return hourList.reduce((a, b) => a + b) / hourList.length;
    }).toList();

    setState(() => hourlyAverages = averages);
  }

  /// ---------- X-Axis hour formatter ----------
  String hourLabel(int hour) {
    const labels = [
      "12AM", "1AM", "2AM", "3AM", "4AM", "5AM",
      "6AM", "7AM", "8AM", "9AM", "10AM", "11AM",
      "12PM", "1PM", "2PM", "3PM", "4PM", "5PM",
      "6PM", "7PM", "8PM", "9PM", "10PM", "11PM",
    ];
    return labels[hour];
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat("MMMM d, yyyy").format(dayShown);

    return Scaffold(
      appBar: AppBar(
        title: const Text("5 Days Ago Breath Rate"),
        backgroundColor: Color.fromARGB(255, 172, 198, 170),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            /// ------ DATE DISPLAY ------
            /// ------ DATE + DESCRIPTION ROW ------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Date: $formattedDate   ",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                /// --- NEW TEXT: “Breaths per minute daily average” ---
                Text(
                  "Breaths per minute daily average",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),


            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  minY: 0,
                  maxY: 40,
                  barGroups: List.generate(24, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: hourlyAverages[index],
                          color: Colors.green,
                          width: 12,
                        ),
                      ],
                    );
                  }),

                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,   // extra space because labels are vertical
                        getTitlesWidget: (value, meta) {
                          int hour = value.toInt();
                          if (hour < 0 || hour > 23) return const SizedBox.shrink();

                          // Convert 0–23 to "12AM, 1AM, ..., 12PM ..."
                          String label;
                          if (hour == 0) label = "12AM";
                          else if (hour < 12) label = "${hour}AM";
                          else if (hour == 12) label = "12PM";
                          else label = "${hour - 12}PM";

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: RotatedBox(
                              quarterTurns: 3,   // 90° rotation
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          if (value % 20 == 0) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
