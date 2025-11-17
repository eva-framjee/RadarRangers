// import 'package:flutter/material.dart';
// import 'liveBRWavePage.dart';

// class BreathDataPage extends StatelessWidget {
//   const BreathDataPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Breath Rate Data'),
//         backgroundColor: Colors.blue,
//       ),
//       body: const LiveBreathWavePage(),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'liveBRWavePage.dart';   // <--- Make sure this import exists

class BreathDataPage extends StatelessWidget {
  const BreathDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breath Rate Data'),
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
            child: LiveBreathWavePage(),   // <--- This displays the waveform
          ),
        ],
      ),
    );
  }
}