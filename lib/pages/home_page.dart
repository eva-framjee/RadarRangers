import 'package:flutter/material.dart';
import 'login_page.dart';
import 'PatternStats_page.dart';
import 'statHistoryPage.dart';
import 'personalHistoryPage.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  final String username;
  final String uid;

  const HomePage({
    super.key,
    required this.username,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        backgroundColor: Color.fromARGB(255, 172, 198, 170),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            /// WELCOME TEXT
            Text(
              'Welcome, $username!',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            /// DAILY STATS
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatsPage()),
                );
              },
              child: _buildButton("Daily Stats"),
            ),

            const SizedBox(height: 20),

            /// STAT HISTORY
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatHistoryPage(uid: uid),
                  ),
                );
              },
              child: _buildButton("Stat History"),
            ),

            const SizedBox(height: 20),

            /// PERSONAL HISTORY
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PersonalHistoryPage(username: username),
                  ),
                );
              },
              child: _buildButton("Personal History"),
            ),

            const SizedBox(height: 40),

            /// LOG OUT
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 122, 149, 216),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 40),

            /// Generating test data
            ElevatedButton(
              onPressed: () async {
                await generateDummyDataMonthly(uid);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Dummy HR + BR Data Added for 4 Weeks!"),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: const Text("Generate Test HR + BR Data"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 172, 198, 170),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color.fromARGB(255, 16, 93, 90),
          width: 2,
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}


/// ------------------------------------------------------
///   Generate *4 weeks* of HR + BR dummy data
///   → Every 60 minutes for 28 days
///   → Total: 2688 heart + 2688 breath samples
/// ------------------------------------------------------
Future<void> generateDummyDataMonthly(String uid) async {
  int totalHours = 24 * 7 * 4; // 4 weeks of hours = 672

  for (int i = 0; i < totalHours; i++) {
    DateTime timestamp = DateTime.now().subtract(Duration(hours: i));

    int heartValue = 40 + Random().nextInt(80); // HR: 60–140
    int breathValue = 8 + Random().nextInt(14); // BR: 8–22

    /// ----- HEART RATE -----
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("heart_data")
        .add({
      "heart_rate": heartValue,
      "timestamp": timestamp,
    });

    /// ----- BREATH RATE -----
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("breath_data")
        .add({
      "breath_rate": breathValue,
      "timestamp": timestamp,
    });
  }
}
