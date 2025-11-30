import 'package:flutter/material.dart';
import 'breathDataPage.dart';
import 'heartRatePage.dart';
import 'sleepDataPage.dart';

class StatsPage extends StatelessWidget {
  final String username;

  const StatsPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Data'),
        backgroundColor: Color.fromARGB(255, 172, 198, 170),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Breath Data Button
            StatButton(
              title: 'Breath Data',
              color: Colors.blue.shade100,
              icon: Icons.air,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BreathDataPage()),
                );
              },
            ),

            const SizedBox(height: 20),

            // Heart Rate Button
            StatButton(
              title: 'Heart Rate',
              color: Colors.red.shade100,
              icon: Icons.favorite,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HeartRatePage(username: username),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // You can add other StatButton widgets here
          ],
        ),
      ),
    );
  }
}

//
// button
//

class StatButton extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const StatButton({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.4),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.black54),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
