import 'package:flutter/material.dart';

class SleepDataPage extends StatelessWidget {
  const SleepDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Data'),
        backgroundColor: Colors.purple,
      ),
      body: const Center(
        child: Text(
          'Sleep Data Page',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
