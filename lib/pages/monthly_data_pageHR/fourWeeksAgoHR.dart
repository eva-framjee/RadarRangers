import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class FourWeeksAgoPageHR extends StatefulWidget {
  final String uid;
  const FourWeeksAgoPageHR({super.key, required this.uid});

  @override
  State<FourWeeksAgoPageHR> createState() => _FourWeeksAgoPageStateHR();
}

class _FourWeeksAgoPageStateHR extends State<FourWeeksAgoPageHR> {
  List<double> dailyAverages = List.filled(7, 0);

  late DateTime startDate;
  late DateTime endDate;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();

      // Normalize to midnight today
      final todayMidnight = DateTime(now.year, now.month, now.day);

      // 4 week ago = the 7-day block BEFORE this week
      startDate = todayMidnight.subtract(const Duration(days: 35));
      endDate = todayMidnight.subtract(const Duration(days: 28));

      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.uid)
          .collection("heart_data")
          .where("timestamp",
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where("timestamp", isLessThan: Timestamp.fromDate(endDate))
          .orderBy("timestamp")
          .get();

      final buckets = List.generate(7, (_) => <double>[]);

      for (final doc in snapshot.docs) {
        final ts = (doc["timestamp"] as Timestamp).toDate();
        final hr = (doc["heart_rate"] as num).toDouble();

        final dayIndex =
            ts.difference(startDate).inDays.clamp(0, 6);

        buckets[dayIndex].add(hr);
      }

      final averages = buckets.map((list) {
        if (list.isEmpty) return 0.0;
        final sum = list.reduce((a, b) => a + b);
        return sum / list.length;
      }).toList();

      if (!mounted) return;
      setState(() {
        dailyAverages = averages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String formatRange(DateTime s, DateTime e) {
    final formatter = DateFormat("MMM d");
    // subtract 1 day from end so label shows correct range
    return "${formatter.format(s)} - ${formatter.format(e.subtract(const Duration(days: 1)))}";
  }

  @override
  Widget build(BuildContext context) {
    final rangeText = formatRange(startDate, endDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("4 Weeks Ago (Daily Avg)"),
        backgroundColor: const Color.fromARGB(255, 172, 198, 170),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
                ? Center(child: Text("Error: $_error"))
                : Column(
                    children: [
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
                            "Beats per minute weekly average",
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 12),
                          child: BarChart(
                            BarChartData(
                              minY: 0,
                              maxY: 220,

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

                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  axisNameWidget: const Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      "Heart Rate (BPM)",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  axisNameSize: 26,
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 20,
                                    reservedSize: 44,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),

                                bottomTitles: AxisTitles(
                                  axisNameWidget: const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Text(
                                      "Day",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  axisNameSize: 24,
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        "Day ${value.toInt() + 1}",
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),

                                topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),

                              gridData: FlGridData(show: true),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}