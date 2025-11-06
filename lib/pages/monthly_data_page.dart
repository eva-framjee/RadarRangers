import 'package:flutter/material.dart';
import 'monthly_data_page/oneWeekAgo.dart';
import 'monthly_data_page/twoWeeksAgo.dart';
import 'monthly_data_page/threeWeeksAgo.dart';
import 'monthly_data_page/fourWeeksAgo.dart';

class MonthlyDataPage extends StatelessWidget {
  const MonthlyDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("This Month's Data"),
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
                  "Monthly trend visualization placeholder",
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Buttons for each Week
            
            Expanded(
              child: ListView(
                children: [
                  _buildWeekButton(context, "1 Week Ago", const OneWeekAgoPage()),
                  _buildWeekButton(context, "2 Weeks Ago", const TwoWeeksAgoPage()),
                  _buildWeekButton(context, "3 Weeks Ago", const ThreeWeeksAgoPage()),
                  _buildWeekButton(context, "4 Weeks Ago", const FourWeeksAgoPage()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable button builder
  Widget _buildWeekButton(BuildContext context, String title, Widget page) {
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




// make a trendline
// can you make in this page to where it will have 

// and then have buttons that will show 1 week ago, 2 weeks ago, 3 weeks ago, 4 weeks ago