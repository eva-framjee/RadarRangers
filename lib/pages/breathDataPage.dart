import 'package:flutter/material.dart';

class BreathDataPage extends StatelessWidget {
  const BreathDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breath Data'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          'Breath Data Page',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
