import 'package:flutter/material.dart';
import 'liveBRWavePage.dart';

class BreathDataPage extends StatelessWidget {
  final String uid;

  const BreathDataPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respiratory Rate Data'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Live Breath Rate Waveform",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LiveBreathWavePage(uid: uid),
          ),
        ],
      ),
    );
  }
}