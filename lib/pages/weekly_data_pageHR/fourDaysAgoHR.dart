import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class FourDaysAgoPage extends StatefulWidget {
  final String uid; // must be the Firestore doc id: users/{uid}
  const FourDaysAgoPage({super.key, required this.uid});

  @override
  State<FourDaysAgoPage> createState() => _FourDaysAgoPageState();
}

class _FourDaysAgoPageState extends State<FourDaysAgoPage> {
  List<double> hourlyAverages = List.filled(24, 0);
  late DateTime dayShown;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    dayShown = DateTime.now().subtract(const Duration(days: 4));
    fetchFourDaysAgoData();
  }

  /// "4 days ago" = the calendar day from 2 days ago (12:00 AM -> 11:59 PM)
  Future<void> fetchFourDaysAgoData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final day = DateTime.now().subtract(const Duration(days: 4));
      final start = DateTime(day.year, day.month, day.day); // 4 days ago 12:00 AM
      final end = start.add(const Duration(days: 1));       // 3 day ago 12:00 AM

      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.uid)
          .collection("heart_data")
          .where("timestamp", isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where("timestamp", isLessThan: Timestamp.fromDate(end))
          .orderBy("timestamp")
          .get();

      final buckets = List.generate(24, (_) => <double>[]);

      for (final doc in snapshot.docs) {
        final ts = (doc["timestamp"] as Timestamp).toDate();
        final hr = (doc["heart_rate"] as num).toDouble();

        final hour = ts.hour;
        if (hour >= 0 && hour <= 23) {
          buckets[hour].add(hr);
        }
      }

      final averages = buckets.map((list) {
        if (list.isEmpty) return 0.0;
        final sum = list.reduce((a, b) => a + b);
        return sum / list.length;
      }).toList();

      if (!mounted) return;
      setState(() {
        hourlyAverages = averages;
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

  String _hourLabel(int hour) {
    if (hour == 0) return "12AM";
    if (hour < 12) return "${hour}AM";
    if (hour == 12) return "12PM";
    return "${hour - 12}PM";
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat("MMMM d, yyyy").format(
      DateTime(dayShown.year, dayShown.month, dayShown.day),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("4 Days Ago Heart Rate"),
        backgroundColor: const Color.fromARGB(255, 172, 198, 170),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Couldn’t load data.\n$_error",
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: fetchFourDaysAgoData,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
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
                          const Text(
                            "Heart rate hourly average",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
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
                              alignment: BarChartAlignment.spaceAround,
                              minY: 0,
                              maxY: 220,
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
                                  axisNameSize: 24,
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 44,
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
                                bottomTitles: AxisTitles(
                                  axisNameWidget: const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Text(
                                      "Hour of Day",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  axisNameSize: 26,
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      final hour = value.toInt();
                                      if (hour < 0 || hour > 23) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: Text(
                                            _hourLabel(hour),
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        ),
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