import 'package:flutter/material.dart';

class HeartRatePage extends StatelessWidget {
  const HeartRatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate Data'),
        backgroundColor: Colors.red,
      ),
      body: const Center(
        child: Text(
          'Heart Rate Page',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
