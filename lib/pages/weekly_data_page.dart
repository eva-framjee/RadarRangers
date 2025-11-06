import 'package:flutter/material.dart';
import 'weekly_data_page/oneDayAgo.dart';
import 'weekly_data_page/twoDaysAgo.dart';
import 'weekly_data_page/threeDaysAgo.dart';
import 'weekly_data_page/fourDaysAgo.dart';
import 'weekly_data_page/fiveDaysAgo.dart';
import 'weekly_data_page/sixDaysAgo.dart';
import 'weekly_data_page/sevenDaysAgo.dart';

class WeeklyDataPage extends StatelessWidget {
  const WeeklyDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("This Week's Data"),
        backgroundColor: const Color.fromARGB(255, 172, 198, 170),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Placeholder Box for Trend/Overview
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border.all(
                  color: const Color.fromARGB(255, 16, 93, 90),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  "Weekly trend visualization placeholder",
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Buttons for each day
            Expanded(
              child: ListView(
                children: [
                  _buildDayButton(context, "1 Day Ago", const OneDayAgoPage()),
                  _buildDayButton(context, "2 Days Ago", const TwoDaysAgoPage()),
                  _buildDayButton(context, "3 Days Ago", const ThreeDaysAgoPage()),
                  _buildDayButton(context, "4 Days Ago", const FourDaysAgoPage()),
                  _buildDayButton(context, "5 Days Ago", const FiveDaysAgoPage()),
                  _buildDayButton(context, "6 Days Ago", const SixDaysAgoPage()),
                  _buildDayButton(context, "7 Days Ago", const SevenDaysAgoPage()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable button builder
  Widget _buildDayButton(BuildContext context, String title, Widget page) {
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
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
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
