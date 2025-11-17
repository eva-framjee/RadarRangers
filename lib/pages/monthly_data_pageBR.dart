
import 'package:flutter/material.dart';
import 'monthly_data_pageBR/oneWeekAgoBR.dart';
import 'monthly_data_pageBR/twoWeeksAgoBR.dart';
import 'monthly_data_pageBR/threeWeeksAgoBR.dart';
import 'monthly_data_pageBR/fourWeeksAgoBR.dart';

class MonthlyDataPageBR extends StatelessWidget {
  final String uid; // ← store UID

  const MonthlyDataPageBR({super.key, required this.uid}); // ← require UID

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("This Month's Respiratory Data"),
        backgroundColor: Color.fromARGB(255, 172, 198, 170),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const SizedBox(height: 30),

            Expanded(
              child: ListView(
                children: [
                  _buildWeekButton(context, "1 Week Ago",
                      OneWeekAgoPageBR(uid: uid)),
                  _buildWeekButton(context, "2 Weeks Ago",
                      TwoWeeksAgoPageBR(uid: uid)),
                  _buildWeekButton(context, "3 Weeks Ago",
                      ThreeWeeksAgoPageBR(uid: uid)),
                  _buildWeekButton(context, "4 Weeks Ago",
                      FourWeeksAgoPageBR(uid: uid)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekButton(
      BuildContext context, String title, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 172, 198, 170),
          border: Border.all(
            color: const Color.fromARGB(255, 16, 93, 90),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
    );
  }
}

