import 'package:flutter/material.dart';

// ✅ Make sure all imports point to the correct paths inside your project
import 'package:flutter_application_1/pages/weekly_data_pageHR/oneDayAgoHR.dart';
import 'package:flutter_application_1/pages/weekly_data_pageHR/twoDaysAgoHR.dart';
import 'package:flutter_application_1/pages/weekly_data_pageHR/threeDaysAgoHR.dart';
import 'package:flutter_application_1/pages/weekly_data_pageHR/fourDaysAgoHR.dart';
import 'package:flutter_application_1/pages/weekly_data_pageHR/fiveDaysAgoHR.dart';
import 'package:flutter_application_1/pages/weekly_data_pageHR/sixDaysAgoHR.dart';
import 'package:flutter_application_1/pages/weekly_data_pageHR/sevenDaysAgoHR.dart';

class WeeklyDataPageHR extends StatelessWidget {
  final String uid; // ✅ receive UID from StatHistoryPage
  const WeeklyDataPageHR({super.key, required this.uid}); // 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("This Week's Heart Rate Data"),
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
                  _buildDayButton(context, "1 Day Ago", OneDayAgoPage(uid: uid)),
                  _buildDayButton(context, "2 Days Ago", TwoDaysAgoPage(uid: uid)),
                  _buildDayButton(context, "3 Days Ago", ThreeDaysAgoPage(uid: uid)),
                  _buildDayButton(context, "4 Days Ago", FourDaysAgoPage(uid: uid)),
                  _buildDayButton(context, "5 Days Ago", FiveDaysAgoPage(uid: uid)),
                  _buildDayButton(context, "6 Days Ago", SixDaysAgoPage(uid: uid)),
                  _buildDayButton(context, "7 Days Ago", SevenDaysAgoPage(uid: uid)),
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


// think about a trendline
// show average data from each day potentially?
// so a tab that says: 1 day ago, 2 days ago, 3 days ago, 4 days ago, 5 days ago, 6 days, 7 days ago
// under pages I have created seven different pages that are titled "oneDayAgo.dart" etc. 
// can you write a code that will have a box that is for now a place holder in which I will add data later, and then under, buttons that will link to seven different pages that will be entitled "One Day Ago" etc. 
