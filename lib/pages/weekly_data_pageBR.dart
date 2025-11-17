import 'package:flutter/material.dart';

// ✅ Make sure all imports point to the correct paths inside your project
import 'package:flutter_application_1/pages/weekly_data_pageBR/oneDayAgoBR.dart';
import 'package:flutter_application_1/pages/weekly_data_pageBR/twoDaysAgoBR.dart';
import 'package:flutter_application_1/pages/weekly_data_pageBR/threeDaysAgoBR.dart';
import 'package:flutter_application_1/pages/weekly_data_pageBR/fourDaysAgoBR.dart';
import 'package:flutter_application_1/pages/weekly_data_pageBR/fiveDaysAgoBR.dart';
import 'package:flutter_application_1/pages/weekly_data_pageBR/sixDaysAgoBR.dart';
import 'package:flutter_application_1/pages/weekly_data_pageBR/sevenDaysAgoBR.dart';

class WeeklyDataPageBR extends StatelessWidget {
  final String uid; // ✅ receive UID from StatHistoryPage
  const WeeklyDataPageBR({super.key, required this.uid}); // 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("This Week's Respiratory Rate Data"),
        backgroundColor: const Color.fromARGB(255, 172, 198, 170),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),

            // ✅ Buttons for each day of the past week
            Expanded(
              child: ListView(
                children: [
                  _buildDayButton(context, "1 Day Ago", OneDayAgoPageBR(uid: uid)),
                  _buildDayButton(context, "2 Days Ago", TwoDaysAgoPageBR(uid: uid)),
                  _buildDayButton(context, "3 Days Ago", ThreeDaysAgoPageBR(uid: uid)),
                  _buildDayButton(context, "4 Days Ago", FourDaysAgoPageBR(uid: uid)),
                  _buildDayButton(context, "5 Days Ago", FiveDaysAgoPageBR(uid: uid)),
                  _buildDayButton(context, "6 Days Ago", SixDaysAgoPageBR(uid: uid)),
                  _buildDayButton(context, "7 Days Ago", SevenDaysAgoPageBR(uid: uid)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Reusable button builder — now correctly navigates to the page passed in
Widget _buildDayButton(BuildContext context, String title, Widget page) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 172, 198, 170),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.all(16),
        side: const BorderSide(
          color: Color.fromARGB(255, 16, 93, 90),
          width: 2,
        ),
      ),
      onPressed: () {
        print("🟢 Navigating to $title page");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

}