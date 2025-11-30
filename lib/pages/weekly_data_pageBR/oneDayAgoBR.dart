import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class OneDayAgoPageBR extends StatefulWidget {
  final String uid;

  const OneDayAgoPageBR({super.key, required this.uid});

  @override
  State<OneDayAgoPageBR> createState() => _OneDayAgoPageStateBR();
}

class _OneDayAgoPageStateBR extends State<OneDayAgoPageBR> {
  List<double> hourlyAverages = List.filled(24, 0);
  late DateTime dayShown;

  @override
  void initState() {
    super.initState();
    dayShown = DateTime.now().subtract(const Duration(days: 1));
    fetchOneDayDataBR();
  }

  Future<void> fetchOneDayDataBR() async {
    DateTime now = DateTime.now();
    DateTime start = now.subtract(const Duration(days: 1));
    DateTime end = now;

    try {
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

      List<double> averages = buckets.map<double>((hourList) {
        if (hourList.isEmpty) return 0.0;
        return hourList.reduce((a, b) => a + b) / hourList.length;
      }).toList();

      setState(() => hourlyAverages = averages);
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  String hourLabel(int h) {
    final times = [
      "12AM","1AM","2AM","3AM","4AM","5AM","6AM","7AM","8AM","9AM","10AM","11AM",
      "12PM","1PM","2PM","3PM","4PM","5PM","6PM","7PM","8PM","9PM","10PM","11PM"
    ];
    return times[h];
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat("MMMM d, yyyy").format(dayShown);

    return Scaffold(
      appBar: AppBar(
        title: const Text("1 Day Ago Breath Rate"),
        backgroundColor: const Color.fromARGB(255, 172, 198, 170),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(

          children: [
            /// ⭐ DATE DISPLAY ⭐
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
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Transform.rotate(
                            angle: -1.57, // rotate 90 degrees
                            child: Text(
                              hourLabel(value.toInt()),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),

                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 5,
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
