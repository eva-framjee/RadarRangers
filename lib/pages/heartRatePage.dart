import 'package:flutter/material.dart';
import 'liveHRWavePage.dart';

class HeartRatePage extends StatelessWidget {
  final String username;

  const HeartRatePage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate Data'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Live Heart Rate Waveform",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          
          Expanded(
            child: LiveHeartWavePage(username: username),
          ),
        ],
      ),
    );
  }
}
