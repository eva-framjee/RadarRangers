import 'package:flutter/material.dart';

class UserManualPage extends StatelessWidget {
  const UserManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Manual"),
        backgroundColor: const Color.fromARGB(255, 172, 198, 170),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            "USER MANUAL\n\n"
            "Daily Stats: View your live heart rate and breathing rate.\n\n"
            "Stat History: Review your past heart and breathing data.\n\n"
            "Personal History: Explore trends and averages over time.\n\n"
            "• Alerts: Notifications appear when values go outside normal ranges.\n\n"
            "For medical concerns, consult a healthcare professional.",
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
      ),
    );
  }
}
